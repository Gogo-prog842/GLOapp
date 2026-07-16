import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/league.dart';
import '../data/models/season.dart';
import '../data/models/user_role.dart';
import '../data/repositories/app_services.dart';

class AppController extends ChangeNotifier {
  AppController(this._services);

  final AppServices _services;
  StreamSubscription<AuthState>? _authSubscription;

  bool _isLoading = true;
  String? _error;
  List<League> _leagues = const [];
  List<Season> _seasons = const [];
  int _selectedLeagueId = 1;
  int? _selectedSeasonId;
  UserRole _role = const UserRole(type: UserRoleType.guest);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<League> get leagues => _leagues;
  List<Season> get seasons => _seasons;
  int get selectedLeagueId => _selectedLeagueId;
  int? get selectedSeasonId => _selectedSeasonId;
  UserRole get role => _role;
  Session? get session => _services.authRepository.currentSession;

  League? get selectedLeague {
    for (final league in _leagues) {
      if (league.id == _selectedLeagueId) return league;
    }
    return null;
  }

  Season? get selectedSeason {
    for (final season in _seasons) {
      if (season.id == _selectedSeasonId) return season;
    }
    return null;
  }

  Future<void> initialize() async {
    _authSubscription = _services.authRepository.authChanges.listen((_) async {
      await refreshRole();
    });
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _leagues = await _services.leagueRepository.fetchLeagues();
      if (_leagues.isNotEmpty && !_leagues.any((league) => league.id == _selectedLeagueId)) {
        _selectedLeagueId = _leagues.first.id;
      }
      await _loadSeasons();
      _role = await _services.authRepository.resolveRole();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSeasons() async {
    _seasons = await _services.leagueRepository.fetchSeasons(_selectedLeagueId);
    final active = _seasons.where((season) => season.isActive).firstOrNull;
    if (_selectedSeasonId == null ||
        !_seasons.any((season) => season.id == _selectedSeasonId)) {
      _selectedSeasonId = active?.id ?? _seasons.firstOrNull?.id;
    }
  }

  Future<void> selectLeague(int leagueId) async {
    if (_selectedLeagueId == leagueId) return;
    _selectedLeagueId = leagueId;
    _selectedSeasonId = null;
    _isLoading = true;
    notifyListeners();
    try {
      await _loadSeasons();
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectSeason(int? seasonId) {
    if (_selectedSeasonId == seasonId) return;
    _selectedSeasonId = seasonId;
    notifyListeners();
  }

  Future<void> refreshRole() async {
    _role = await _services.authRepository.resolveRole();
    notifyListeners();
  }

  Future<void> retry() => _loadInitialData();

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
