# Terraform Variables

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "instance_type" {
  description = "EC2 執行個體類型"
  type        = string
  default     = "m5.large"  # 2 vCPU, 8GB RAM - 省錢模式
}

variable "ami_id" {
  description = "AMI ID for Amazon Linux 2023 (ap-northeast-1)"
  type        = string
  default     = "ami-0c3c2cb5f8551a7d6"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 100
}

variable "key_pair_name" {
  description = "EC2 Key Pair 名稱"
  type        = string
  default     = "soc-key-pair"
}

variable "environment" {
  description = "環境名稱"
  type        = string
  default     = "soc"
}

variable "owner" {
  description = "資源擁有者"
  type        = string
  default     = "SOC-龍蝦"
}