resource "aws_quicksight_account_subscription" "this" {
  count = var.enable_quicksight_subscription ? 1 : 0

  account_name          = var.quicksight_account_name
  authentication_method = var.authentication_method
  edition               = var.quicksight_edition
  notification_email    = var.admin_email
}

resource "aws_quicksight_group" "analysts" {
  group_name  = "${local.name_prefix}-analysts"
  description = "Analyst group for ${local.name_prefix} QuickSight assets"
}

resource "aws_quicksight_user" "admin" {
  user_name     = var.admin_email
  email         = var.admin_email
  identity_type = "QUICKSIGHT"
  user_role     = "ADMIN"
}

resource "aws_quicksight_group_membership" "admin" {
  group_name  = aws_quicksight_group.analysts.group_name
  member_name = aws_quicksight_user.admin.user_name
}

resource "aws_quicksight_data_source" "sales_s3" {
  data_source_id = "${local.name_prefix}-sales-s3"
  name           = "${local.name_prefix} Sales S3 Source"
  type           = "S3"

  parameters {
    s3 {
      manifest_file_location {
        bucket = aws_s3_bucket.quicksight_data.bucket
        key    = aws_s3_object.manifest.key
      }

      role_arn = aws_iam_role.quicksight_s3.arn
    }
  }

  depends_on = [
    aws_s3_bucket_policy.quicksight_data,
    aws_iam_role_policy.quicksight_s3,
  ]
}

resource "aws_quicksight_data_set" "sales" {
  data_set_id = local.data_set_id
  name        = "${local.name_prefix} Sales Dataset"
  import_mode = "SPICE"

  physical_table_map {
    physical_table_map_id = "sales-table"

    s3_source {
      data_source_arn = aws_quicksight_data_source.sales_s3.arn

      input_columns {
        name = "order_id"
        type = "STRING"
      }

      input_columns {
        name = "product"
        type = "STRING"
      }

      input_columns {
        name = "region"
        type = "STRING"
      }

      input_columns {
        name = "sales_amount"
        type = "DECIMAL"
      }

      input_columns {
        name = "order_date"
        type = "STRING"
      }

      upload_settings {
        format          = "CSV"
        delimiter       = ","
        text_qualifier  = "\""
        contains_header = true
      }
    }
  }

  permissions {
    actions = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet",
      "quicksight:CreateIngestion",
      "quicksight:CancelIngestion",
      "quicksight:UpdateDataSetPermissions",
    ]
    principal = aws_quicksight_user.admin.arn
  }

  permissions {
    actions = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions",
    ]
    principal = aws_quicksight_group.analysts.arn
  }
}

resource "aws_quicksight_ingestion" "sales_initial" {
  data_set_id    = aws_quicksight_data_set.sales.data_set_id
  ingestion_id   = "initial-load"
  ingestion_type = "FULL_REFRESH"

  depends_on = [
    aws_quicksight_data_set.sales,
    aws_s3_object.sales_csv,
  ]
}

resource "aws_quicksight_dashboard" "sales" {
  count = var.create_dashboard ? 1 : 0

  dashboard_id        = local.dashboard_id
  name                = "${local.name_prefix} Sales Dashboard"
  version_description = "Initial Terraform-managed dashboard"

  definition {
    data_set_identifiers_declarations {
      data_set_arn = aws_quicksight_data_set.sales.arn
      identifier   = "sales_dataset"
    }

    sheets {
      sheet_id = "sales-overview"
      name     = "Sales Overview"
      title    = "Sales Overview"

      visuals {
        bar_chart_visual {
          visual_id = "sales-by-region"

          title {
            format_text {
              plain_text = "Total Sales by Region"
            }
          }

          chart_configuration {
            field_wells {
              bar_chart_aggregated_field_wells {
                category {
                  categorical_dimension_field {
                    field_id = "region-dimension"

                    column {
                      data_set_identifier = "sales_dataset"
                      column_name         = "region"
                    }
                  }
                }

                values {
                  numerical_measure_field {
                    field_id = "sales-sum"

                    column {
                      data_set_identifier = "sales_dataset"
                      column_name         = "sales_amount"
                    }

                    aggregation {
                      function = "SUM"
                    }
                  }
                }
              }
            }
          }
        }
      }

      visuals {
        table_visual {
          visual_id = "sales-table"

          title {
            format_text {
              plain_text = "Sales Detail"
            }
          }

          chart_configuration {
            field_wells {
              table_aggregated_field_wells {
                group_by {
                  categorical_dimension_field {
                    field_id = "product-dimension"

                    column {
                      data_set_identifier = "sales_dataset"
                      column_name         = "product"
                    }
                  }
                }

                values {
                  numerical_measure_field {
                    field_id = "sales-amount"

                    column {
                      data_set_identifier = "sales_dataset"
                      column_name         = "sales_amount"
                    }

                    aggregation {
                      function = "SUM"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  permissions {
    principal = aws_quicksight_user.admin.arn
    actions = [
      "quicksight:DescribeDashboard",
      "quicksight:ListDashboardVersions",
      "quicksight:UpdateDashboardPermissions",
      "quicksight:QueryDashboard",
      "quicksight:DescribeDashboardPermissions",
      "quicksight:UpdateDashboard",
      "quicksight:DeleteDashboard",
    ]
  }

  depends_on = [
    aws_quicksight_ingestion.sales_initial,
  ]
}
