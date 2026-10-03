variable "create_participant_user" {
  description = "Create the no-permission participant IAM user + credentials file. Set false to reuse the Overly-permissive IAM lab's participant credentials."
  type        = bool
  default     = true
}
