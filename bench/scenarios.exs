# Benchmark all integration test scenarios (parse and render).
# MIX_ENV=test mix run bench/scenarios.exs

dir = "test/solid/integration/scenarios"
opts = [custom_filters: Solid.CustomFilters]

measure = fn fun ->
  for _ <- 1..50, do: fun.()
  times = for(_ <- 1..200, do: elem(:timer.tc(fun), 0))
  Enum.sort(times) |> Enum.at(100)
end

IO.puts(String.pad_trailing("scenario", 22) <> String.pad_leading("parse", 10) <> String.pad_leading("render", 10) <> String.pad_leading("total", 10))
IO.puts(String.duplicate("-", 52))

for scenario <- File.ls!(dir) |> Enum.sort() do
  template_dir = Path.join(dir, scenario)
  liquid = File.read!(Path.join(template_dir, "input.liquid"))
  context = Jason.decode!(File.read!(Path.join(template_dir, "input.json")))

  sopts =
    if File.ls!(template_dir) |> Enum.any?(&String.starts_with?(&1, "_")),
      do: [{:file_system, {Solid.LocalFileSystem, Solid.LocalFileSystem.new(template_dir)}} | opts],
      else: opts

  parsed = Solid.parse!(liquid, sopts)
  p = measure.(fn -> Solid.parse!(liquid, sopts) end)
  r = measure.(fn -> Solid.render!(parsed, context, sopts) end)

  IO.puts(String.pad_trailing(scenario, 22) <> String.pad_leading("#{p}", 10) <> String.pad_leading("#{r}", 10) <> String.pad_leading("#{p + r}", 10))
end

IO.puts("\nAll times in μs (median of 200 iterations).")
