import sys
import networkx as nx
import matplotlib.pyplot as plt
from networkx.drawing.nx_pydot import read_dot

sys.stdout.reconfigure(encoding='utf-8')

if len(sys.argv) < 2:
    print("Ошибка: Укажите путь к файлу .dot")
    sys.exit(1)

dot_file = sys.argv[1]
is_directed = sys.argv[2] == "directed"

# Читаем граф из файла
G = read_dot(dot_file)

# Преобразуем строки в числа для веса рёбер
for u, v, data in G.edges(data=True):
    if 'weight' in data:
        try:
            data['weight'] = float(data['weight'])  # Преобразуем вес в число
        except ValueError:
            print(f"Ошибка преобразования веса для ребра ({u}, {v}): {data['weight']}")

# Создаём словарь для переименования узлов
labels = {node: data["label"].strip('"') for node, data in G.nodes(data=True) if "label" in data}

# Переименовываем узлы
G = nx.relabel_nodes(G, labels)

# Преобразуем MultiGraph в соответствующий тип графа
G = nx.DiGraph(G) if is_directed else nx.Graph(G)

# Принудительно удаляем атрибут 'weight' у всех рёбер, если граф невзвешенный
if not any('weight' in data and data['weight'] != 1.0 for _, _, data in G.edges(data=True)):
    for u, v, data in G.edges(data=True):
        data.pop('weight', None)  # Удаляем 'weight', если он есть

# Вывод матрицы смежности
adj_matrix = nx.to_numpy_array(G, dtype=int)
print("\nМатрица смежности")
print(adj_matrix)

# Рисуем граф
pos = nx.spring_layout(G)  # Автоматическое расположение узлов
nx.draw(G, pos, with_labels=True, node_color="lightblue", edge_color="gray",
        node_size=3000, font_size=12, arrows=is_directed)

# Добавляем подписи к рёбрам только если граф взвешенный
if any('weight' in data for _, _, data in G.edges(data=True)):
    edge_labels = nx.get_edge_attributes(G, 'weight')
    nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, font_size=10)

# Сохраняем картинку графа
plt.savefig(dot_file.replace(".dot", ".png"))
plt.show()
