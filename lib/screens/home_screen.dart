import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/chicken.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> stats = {};
  int totalEggs = 0;
  Map<int, int> eggProduction = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final loadedStats = await appState.getChickenStats();
    final eggs = await appState.getTotalEggCount();
    final production = await appState.getEggProductionByChicken();

    setState(() {
      stats = loadedStats;
      totalEggs = eggs;
      eggProduction = production;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Meu Galinheiro',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).initializeApp();
              _loadStats();
            },
          ),
          Consumer<AppState>(
            builder: (context, appState, _) {
              return IconButton(
                icon: Icon(
                  appState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  appState.toggleDarkMode();
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<AppState>(context, listen: false).initializeApp();
          await _loadStats();
        },
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            if (appState.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (appState.chickens.isEmpty) {
              return _buildEmptyState();
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildEggProductionChart(),
                  const SizedBox(height: 24),
                  _buildRecentChickens(appState.chickens),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: GradientFAB(
        icon: Icons.add,
        tooltip: 'Adicionar Dados de Teste',
        onPressed: () async {
          await Provider.of<AppState>(context, listen: false).loadDummyData();
          await _loadStats();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dados de teste adicionados!'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pets,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma galinha ainda',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione sua primeira galinha!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Provider.of<AppState>(context, listen: false).loadDummyData();
              await _loadStats();
            },
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Dados de Teste'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                stats['total']?.toString() ?? '0',
                Icons.pets,
                AppTheme.lilacLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Saudáveis',
                stats['healthy']?.toString() ?? '0',
                Icons.favorite,
                AppTheme.blueLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Botando',
                stats['laying']?.toString() ?? '0',
                Icons.egg,
                AppTheme.pinkLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Ovos',
                totalEggs.toString(),
                Icons.egg_outlined,
                AppTheme.lilacDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEggProductionChart() {
    if (eggProduction.isEmpty) {
      return const SizedBox.shrink();
    }

    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produção de Ovos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      AppTheme.lilacLight,
      AppTheme.blueLight,
      AppTheme.pinkLight,
      AppTheme.lilacDark,
      AppTheme.blueDark,
      AppTheme.pinkDark,
    ];

    int index = 0;
    return eggProduction.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: entry.value.toString(),
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildRecentChickens(List<Chicken> chickens) {
    final recent = chickens.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Galinhas Recentes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...recent.map((chicken) => _buildChickenCard(chicken)),
      ],
    );
  }

  Widget _buildChickenCard(Chicken chicken) {
    return GradientCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.lilacLight,
          child: Icon(
            chicken.sex == 'Macho' ? Icons.male : Icons.female,
            color: Colors.white,
          ),
        ),
        title: Text(
          chicken.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${chicken.breed} • ${chicken.formattedAge}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(chicken.status),
            borderRadius: BorderRadius.circular(12),
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
}
