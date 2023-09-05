output "address" {
  value       = aws_docdb_cluster.docdb.endpoint
  description = "Connect to the document store at this endpoint"
}

output "port" {
  value       = aws_docdb_cluster.docdb.port
  description = "The port the document store is listening on"
}