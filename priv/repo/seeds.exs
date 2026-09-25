# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     JidoLab.Repo.insert!(%JidoLab.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

count = JidoLab.Docs.index!(Path.join(:code.priv_dir(:jido_lab), "docs"))
IO.puts("Indexed #{count} doc chunks")

if JidoLab.Repo.aggregate(JidoLab.Tickets.Ticket, :count) == 0 do
  JidoLab.Repo.insert!(%JidoLab.Tickets.Ticket{
    title: "Widget arrived cracked",
    email: "sam@example.com",
    priority: "high",
    body: "My Widget Pro (ORD-10422) arrived with a cracked housing."
  })

  JidoLab.Repo.insert!(%JidoLab.Tickets.Ticket{
    title: "Cannot pair with app",
    email: "robin@example.com",
    priority: "normal",
    body: "The companion app never finds my widget over Bluetooth.",
    status: "closed"
  })
end
