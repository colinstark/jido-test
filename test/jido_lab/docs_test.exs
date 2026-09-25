defmodule JidoLab.DocsTest do
  use JidoLab.DataCase, async: false

  alias JidoLab.Docs

  setup do
    Docs.index!(Path.join(:code.priv_dir(:jido_lab), "docs"))
    :ok
  end

  test "chunks markdown by heading" do
    assert [%{heading: "Title"}, %{heading: "Sub", content: "## Sub\nbody"}] =
             Docs.chunk("# Title\nintro\n## Sub\nbody", "x.md")
  end

  test "search ranks the matching section first" do
    assert [%{path: "returns.md", heading: "How refunds are paid"} | _] =
             Docs.search("how long does a refund take?")
  end

  test "search tolerates FTS5 syntax characters and empty input" do
    assert is_list(Docs.search(~s(widget" OR (NEAR -battery*)))
    assert Docs.search("?!") == []
  end
end
