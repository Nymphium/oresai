env "local" {
  src = ["file://schemas/"]
  url = "postgresql://root@localhost:15432/oresai?sslmode=disable"
  dev = "postgresql://root@localhost:15432/dev?sslmode=disable"
}
