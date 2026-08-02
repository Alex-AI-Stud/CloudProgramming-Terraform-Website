
// ================================================
// S3 Bucket
// ================================================

// Bucket erstellen
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
    Project = var.project_name
    Environment = var.environment
  }
}

// Der Bucket öffentlich sperren - Zugriff nur über CloudFront
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true    // Keine öffentlichen Zugriffsregeln
  block_public_policy     = true    // Keine öffentliche Bucket Policy
  ignore_public_acls      = true    // Ignoriere öffentliche ACLs
  restrict_public_buckets = true    // Kein direkter Internetzugriff
}

// Versionierung aktivieren
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}
// Lifecycle Rule
resource "aws_s3_bucket_lifecycle_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    id = "delete-old-versions"
    status = "Enabled"

    // Filter: Regel gilt für alle Objekte im Bucket
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30    // Löscht alte Versionen automatisch nach 30 Tagen
    }
  }
}

// Serverseitige Verschlüsselung (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

// ================================================
// CloudFront Origin Access Control (OAC)
// ================================================

resource "aws_cloudfront_origin_access_control" "website" {
  name = "${var.project_name}-oac"
  description = "OAC für NatureWatch Website"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

// ================================================
// DDOS-Schutz
// ================================================
/*
AWS Shield Standard ist automatisch und kostenlos in jede Cloud Front Distribution
integriert und muss nicht konfiguriert werden. 
BEI ANBIETERWECHSEL: DDOS-Schutz implementieren!
*/

// ================================================
// CloudFront Distribution
// ================================================

resource "aws_cloudfront_response_headers_policy" "website" {
  // Setzt Sicherheits-Header für Browser-Antworten
  name = "${var.project_name}-security-headers"

  security_headers_config {
    // Verhindert dass die Seite in einem iFrame geladen wird
    frame_options {
      frame_option = "DENY"
      override = true
    }
    // Erzwingt HTTPS für eine gewisse Zeitspanne - Industriestandard
    strict_transport_security {
      access_control_max_age_sec = 31536000 // bei erneutem Aufruf startet der Timer wieder von neuem
      override = true
    }
    // Verhindert MIME-Type Sniffing Angriffe -> für zukünftige Uploadfunktionen vorbereitet
    content_type_options {
      override = true
    }
  }
}

resource "aws_cloudfront_distribution" "website" {
  // CloudFront erst erstellen wenn S3 Bucket und Public Access Block fertig sind
  depends_on = [ 
    aws_cloudfront_origin_access_control.website,
    aws_s3_bucket.website,
    aws_s3_bucket_public_access_block.website
  ]
  
  enabled = true
  comment = "NatureWatch e.V. - Statische Webseite"
  default_root_object = "index.html"
  price_class = "PriceClass_All"    // Alle Edge-Standorte Weltweit
  //price_class = "PriceClass_100"      // Nur USA und Europa

  // IPv6 aktivieren
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id = "S3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  } 

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "S3-${var.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"

    min_ttl = 0
    default_ttl = 86400   // 24h in sec
    max_ttl = 31536000    // 1J in sec

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    compress = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.website.id
  }

  // Weltweite Erreichbarkeit
  restrictions {
    geo_restriction {
      restriction_type = "none"   
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project = var.project_name
    Environment = var.environment
  }
}

// ================================================
// S3 Bucket Policy
// ================================================

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  // AWS erwartet Policies in JSON-Format
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals ={
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })
}

// ================================================
// Website Deployment
// ================================================

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.website.id
  key = "index.html"
  source = "index.html"
  content_type = "text/html"
  cache_control = "max-age=86400"
}