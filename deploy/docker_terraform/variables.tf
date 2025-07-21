variable "ssh_public_key" {
  description = "Clé publique SSH à injecter dans le projet OVH"
  type        = string
  sensitive   = true
}
