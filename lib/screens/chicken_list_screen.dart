import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/chicken.dart';
import 'add_chicken_screen.dart';

class ChickenListScreen extends StatefulWidget {
  const ChickenListScreen({super.key});

  @override
  State<ChickenListScreen> createState() => _ChickenListScreenState();
}

class _ChickenListScreenState extends State<ChickenListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'Todos';
  String _filterSex = 'Todos';
  String _sortBy = 'Nome';

  final List<String> _statusFilters = [
    'Todos',
    'Saudável',
    'Doente',
    'Botando',
    'Não Botando'
  ];
  final List<String> _sexFilters = ['Todos', 'Macho', 'Fêmea'];
  final List<String> _sortOptions = ['Nome', 'Idade', 'Raça'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Chicken> _filterAndSortChickens(List<Chicken> chickens) {
    var filtered = chickens.where((chicken) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          chicken.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          chicken.breed.toLowerCase().contains(_searchQuery.toLowerCase());

      // Status filter
      final matchesStatus =
          _filterStatus == 'Todos' || chicken.status == _filterStatus;

      // Sex filter
      final matchesSex = _filterSex == 'Todos' || chicken.sex == _filterSex;

      return matchesSearch && matchesStatus && matchesSex;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'Nome':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Idade':
        filtered.sort((a, b) => b.ageInDays.compareTo(a.ageInDays));
        break;
      case 'Raça':
        filtered.sort((a, b) => a.breed.compareTo(b.breed));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Lista de Galinhas',
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, _) {
                if (appState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (appState.chickens.isEmpty) {
                  return _buildEmptyState();
                }

                final filteredChickens =
                    _filterAndSortChickens(appState.chickens);

                if (filteredChickens.isEmpty) {
                  return _buildNoResultsState();
                }

                return RefreshIndicator(
                  onRefresh: () => appState.loadChickens(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredChickens.length,
                    itemBuilder: (context, index) {
                      return _buildChickenCard(
                          filteredChickens[index], appState);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.rainbowGradient,
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar galinha...',
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Ordenar: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sortOptions.map((option) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(option),
                          selected: _sortBy == option,
                          onSelected: (selected) {
                            setState(() {
                              _sortBy = option;
                            });
                          },
                          selectedColor: AppTheme.lilacLight,
                          labelStyle: TextStyle(
                            color:
                                _sortBy == option ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status),
                          selected: _filterStatus == status,
                          onSelected: (selected) {
                            setState(() {
                              _filterStatus = status;
                            });
                          },
                          selectedColor: AppTheme.blueLight,
                          labelStyle: TextStyle(
                            color: _filterStatus == status
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Sexo: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sexFilters.map((sex) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(sex),
                          selected: _filterSex == sex,
                          onSelected: (selected) {
                            setState(() {
                              _filterSex = sex;
                            });
                          },
                          selectedColor: AppTheme.pinkLight,
                          labelStyle: TextStyle(
                            color:
                                _filterSex == sex ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma galinha cadastrada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione sua primeira galinha!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Nenhum resultado encontrado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tente ajustar os filtros',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChickenCard(Chicken chicken, AppState appState) {
    return GradientCard(
      child: InkWell(
        onTap: () {
          _showChickenDetails(chicken, appState);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _buildChickenAvatar(chicken),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chicken.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${chicken.breed} • ${chicken.sex}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Idade: ${chicken.formattedAge}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(chicken.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chicken.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddChickenScreen(chicken: chicken),
                      ),
                    );
                  } else if (value == 'delete') {
                    _confirmDelete(chicken, appState);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Excluir'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChickenAvatar(Chicken chicken) {
    if (chicken.photoPath != null && File(chicken.photoPath!).existsSync()) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: FileImage(File(chicken.photoPath!)),
      );
    }

    return CircleAvatar(
      radius: 40,
      backgroundColor: AppTheme.lilacLight,
      child: Icon(
        chicken.sex == 'Macho' ? Icons.male : Icons.female,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Saudável':
        return Colors.green;
      case 'Botando':
        return AppTheme.pinkDark;
      case 'Doente':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showChickenDetails(Chicken chicken, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(child: _buildChickenAvatar(chicken)),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    chicken.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Raça', chicken.breed),
                _buildDetailRow('Sexo', chicken.sex),
                _buildDetailRow('Idade', chicken.formattedAge),
                _buildDetailRow('Status', chicken.status),
                if (chicken.color != null)
                  _buildDetailRow('Cor', chicken.color!),
                if (chicken.parentMale != null)
                  _buildDetailRow('Pai', chicken.parentMale!),
                if (chicken.parentFemale != null)
                  _buildDetailRow('Mãe', chicken.parentFemale!),
                if (chicken.healthNotes != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Notas de Saúde:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(chicken.healthNotes!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Chicken chicken, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir ${chicken.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await appState.deleteChicken(chicken.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Galinha excluída com sucesso!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
