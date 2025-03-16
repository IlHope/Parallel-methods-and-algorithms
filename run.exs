# Загружаем модуль GraphProject
alias GraphProject

# Создаем граф
graph = GraphProject.graph_create()

is_directed = case graph do
  %Graph{type: :directed} -> true
  _ -> false
end

GraphProject.save_graph_to_dot(graph, 
								"D:/Моё/Учёба/Магистратура/Семестр 2/Параллельные методы и алгоритмы/graph_visualization/graph.dot",
								"D:/Моё/Учёба/Магистратура/Семестр 2/Параллельные методы и алгоритмы/graph_visualization/visualize.py",
								is_directed
								)