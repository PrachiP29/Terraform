#working for LCR, bi-directional CRR for S3
provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "central"
  region = "eu-central-1"
}

resource "aws_s3_bucket" "bucketone" {
  bucket = "p-tf-test-bucket-01"
  acl    = "private"

  #---- lifecycle rule for 1st bucket -----#
  lifecycle_rule {
    id      = "archive"
    enabled = true
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
  versioning {
    enabled = true
  }
  tags = { Environment : "Dev" }

}

# Enable versioning for bucket one
resource "aws_s3_bucket_versioning" "bucketone" {
  bucket = aws_s3_bucket.bucketone.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "buckettwo" {
  provider = aws.central
  bucket   = "p-tf-test-bucket-02"
  acl      = "private"

  #---- lifecycle rule for 1st bucket -----#
  lifecycle_rule {
    id      = "archive"
    enabled = true
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
  versioning {
    enabled = true
  }
  tags = { Environment : "Dev" }


}
# Enable versioning for bucket two
resource "aws_s3_bucket_versioning" "buckettwo" {
  provider = aws.central
  bucket   = aws_s3_bucket.buckettwo.id
  versioning_configuration {
    status = "Enabled"
  }
}


# CREATE IAM ROLE FOR THE REPLICATION RULE
resource "aws_iam_role" "replication01" {
  name = "tf-iam-role-replication-bucket-01"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication01" {
  name   = "tf-iam-role-policy-replication-bucket-01"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.bucketone.arn}"
      ]
    },
    {
      "Action": [
        "s3: GetObjectVersion",
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.bucketone.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.buckettwo.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "replication01" {
  role       = aws_iam_role.replication01.name
  policy_arn = aws_iam_policy.replication01.arn
}

# CREATE IAM ROLE FOR THE REPLICATION RULE
resource "aws_iam_role" "replication02" {
  name               = "tf-iam-role-replication-bucket-02"
  provider           = aws.central
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication02" {
  name     = "tf-iam-role-policy-replication-bucket-02"
  provider = aws.central
  policy   = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.buckettwo.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.buckettwo.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.bucketone.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "replication02" {
  provider   = aws.central
  role       = aws_iam_role.replication02.name
  policy_arn = aws_iam_policy.replication02.arn
}

# REPLICATION CONFIGURATION for one

resource "aws_s3_bucket_replication_configuration" "bucket01_to_bucket02" {
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.bucketone, aws_s3_bucket.bucketone]

  role   = aws_iam_role.replication01.arn
  bucket = aws_s3_bucket.bucketone.id

  rule {
    id = "bucket-01"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.buckettwo.arn
      storage_class = "STANDARD"
      //replica_kms_key_id = aws_kms_key.buckettwo.arn
    }
   /*  source_selection_criteria {
        sse_kms_encrypted_objects {
          enabled = "true"
        }
      } */

  }
}

# REPLICATION CONFIG FOR TWO
resource "aws_s3_bucket_replication_configuration" "bucket02_to_bucket01" {
  provider = aws.central
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.buckettwo, aws_s3_bucket.buckettwo]

  role   = aws_iam_role.replication02.arn
  bucket = aws_s3_bucket.buckettwo.id

  rule {
    id = "bucket02"


    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.bucketone.arn
      storage_class = "STANDARD"
      //replica_kms_key_id = aws_kms_key.bucketone.arn
    }


  }
}
  
