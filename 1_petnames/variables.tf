variable "cols" {
  description = "number of columns availale to histogram.  Set with `-var cols=$COLUMNS`"
  type = number
  default = 200
}

variable "rows" {
  description = "number of rows availale to histogram.  Set with `-var rows=$LINES`"
  type = number
  default = "50"
}
