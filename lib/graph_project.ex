defmodule GraphProject do
  
  @moduledoc """
  Documentation for `GraphProject`.
  """

  @doc """
  """
  
  alias Graph
  
  def graph_create do
	IO.puts("\nГраф ориентированный? (yes/no): ")
	directed = IO.gets("> ") |> String.trim() |> String.downcase()
	
	IO.puts("\nГраф взвешенный? (yes/no): ")
	weighted = IO.gets("> ") |> String.trim() |> String.downcase()
	
	IO.puts("\nВведите количество вершин: ")
	num_vertices = IO.gets("> ") |> String.trim() |> String.to_integer()
	
	# Определяем тип графа
	graph_type =
	  case directed do
	    "yes" -> :directed
		"no" -> :undirected
		_ ->
		  IO.puts("Ошибка ввода! По умолчанию выбран неориентированный граф.")
		  :undirected
	  end
	
	# Создаем граф с нужным типом
	graph = Graph.new(type: graph_type)
	
	# Определяем минимальное и максимальное количество ребер
	min_edges = num_vertices - 1  # Связный граф: минимум (n-1) рёбер
	max_edges = 
	  case directed do
	    "yes" -> num_vertices * (num_vertices - 1) # Для ориентированного графа
		"no" -> div(num_vertices * (num_vertices - 1), 2) # Для неориентированного графа
		_ ->
		  IO.puts("Ошибка ввода! Выбран геориентированный граф по умолчанию.")
		  div(num_vertices * (num_vertices - 1), 2)
	  end
	
	# Устанавливаем количество ребер умноженое на 1.5 (Для более ветвленного графа)
	mult_vertices = round(num_vertices * 1.5)
	
	IO.puts("\nМинимальное количество рёбер для связного графа: #{mult_vertices}")
	IO.puts("Максимальное количество ребер для такого графа: #{max_edges}")
	
	IO.puts("\nВведите количество ребер:")
	input_edges = IO.gets("> ") |> String.trim() |> String.to_integer()
	
	# Устанавливаем корректное число рёбер
    num_edges =
      cond do
        input_edges < mult_vertices ->
          IO.puts("Число рёбер слишком мало! Будет установлено #{mult_vertices} рёбер.")
          mult_vertices

        input_edges > max_edges ->
          IO.puts("Число рёбер превышает максимум! Будет установлено #{max_edges} рёбер.")
          max_edges

        true ->
          input_edges
      end
	
	# Создаем вершины
	vertices = Enum.map(1..num_vertices, fn i -> :"V#{i}" end)
	# Добавляем их в граф
	graph = Enum.reduce(vertices, graph, fn v, g -> Graph.add_vertex(g, v) end)
	
	# Создаём остовное дерево (чтобы граф был связным)
    {graph, edge_set} = create_spanning_tree(graph, vertices, weighted)

    # Добавляем оставшиеся рёбра
    remaining_edges = num_edges - min_edges
    graph = add_edges(graph, vertices, remaining_edges, directed, weighted, edge_set)

    IO.puts("\nГраф успешно создан!")
	
    IO.puts("\nСписок рёбер:")
	Enum.each(Graph.edges(graph), fn %{v1: v1, v2: v2, label: weight} ->
	  weight_info = if weight != nil, do: " (вес: #{weight})", else: ""
	  IO.puts("#{v1} -> #{v2}#{weight_info}")
	end)
	
	graph
  end



  # Функция для создания связного графа (остовное дерево)
  defp create_spanning_tree(graph, vertices, weighted) do
  {new_graph, edge_set} =
    Enum.reduce(0..(length(vertices) - 2), {graph, MapSet.new()}, fn index, {g, e_set} ->
      v = Enum.at(vertices, index)
      v_next = Enum.at(vertices, index + 1)

      weight = if weighted == "yes", do: :rand.uniform(10), else: nil
      
      g = if weight, do: Graph.add_edge(g, v, v_next, weight: weight, label: "#{weight}"), else: Graph.add_edge(g, v, v_next)
      
      {g, MapSet.put(e_set, {v, v_next})}
    end)

  {new_graph, edge_set}
  end



  # Функция для случайного добавления дополнительных рёбер
  defp add_edges(graph, _vertices, 0, _directed, _weighted, _edge_set), do: graph

  defp add_edges(graph, vertices, remaining_edges, directed, weighted, edge_set) do
    [v1, v2] = Enum.take_random(vertices, 2)

    # Проверяем, нет ли уже такого ребра (для неориентированного графа проверяем в обе стороны)
    edge_exists =
      case directed do
        "yes" -> MapSet.member?(edge_set, {v1, v2})
        "no" -> MapSet.member?(edge_set, {v1, v2}) or MapSet.member?(edge_set, {v2, v1})
      end

    if edge_exists do
      add_edges(graph, vertices, remaining_edges, directed, weighted, edge_set)  # Пробуем снова
    else
	  weight = if weighted == "yes", do: :rand.uniform(10), else: nil
      new_graph = if weight, do: Graph.add_edge(graph, v1, v2, weight: weight, label: "#{weight}"), else: Graph.add_edge(graph, v1, v2)
      new_edge_set = MapSet.put(edge_set, {v1, v2})

      add_edges(new_graph, vertices, remaining_edges - 1, directed, weighted, new_edge_set)
    end
  end
  
  
  
  def save_graph_to_dot(graph, dot_filename, python_script, is_directed) do
	case Graph.to_dot(graph) do
	  {:ok, dot_content} ->
		# Изменяем dot файл
	    fixed_dot_content = 
		  dot_content
		  |> String.split("\n")
		  |> Enum.map(fn line -> 
            if String.contains?(line, "[") or String.contains?(line, "->") do
              line |> String.replace(";", ",") # Заменяем точку с запятой на запятую
            else
              line  # Иначе оставляем строку без изменений
            end
          end)
          |> Enum.join("\n")  # Собираем строки обратно в одну
		
		File.write!(dot_filename, fixed_dot_content)
		IO.puts("\nГраф сохранён в #{dot_filename}")
		
		# Передаем флаг направленности при вызове Python
		direction_flag = if is_directed, do: "directed", else: "undirected"
		
		# Запуск Python-скрипта для визуализации
		case System.cmd("D:/Моё/Учёба/Магистратура/Семестр 2/Параллельные методы и алгоритмы/graph_visualization/venv/Scripts/python", [python_script, dot_filename, direction_flag]) do
		  {output, 0} -> IO.puts("\nВыполнение python-скрипта:\n#{output}")
		  {error_output, exit_code} -> IO.puts("Ошибка в python: #{error_output} (код #{exit_code})")
		end
		
	  {:error, reason} ->
	    IO.puts("Ошибка при генерации DOT: #{inspect(reason)}")
	end
  end
end
