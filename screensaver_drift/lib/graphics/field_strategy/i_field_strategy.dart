part of '../_index.dart';

/// Базовый тип состояния стратегии (может быть любым).
abstract class FieldStrategyState {
  const FieldStrategyState();
}

/// Стратегия расчёта полей: сервер знает только про этот интерфейс.
abstract class FieldStrategy {
  const FieldStrategy();

  /// Уникальный идентификатор стратегии (совпадает со значением strategy в запросе).
  String get id;

  /// Создаёт внутреннее состояние под конкретный запрос (размеры, буферы и т.д.).
  FieldStrategyState createState(FieldConfig config);

  /// Генерирует один кадр.
  FieldFrame generateFrame({
    required FieldConfig config,
    required FieldStrategyState state,
    required double t,
    required double dt,
    required BufferTransferMode transferMode,
  });
}

final Map<String, FieldStrategy> _strategyRegistry = {
  'drift': const DriftStrategy(),
  'pulsate': const PulsateStrategy(),
  'fire': const FireStrategy(),
};

FieldStrategy _strategyForId(String id) =>
    _strategyRegistry[id.toLowerCase()] ?? const DriftStrategy();

/// Публичный доступ к стратегиям по идентификатору.
FieldStrategy strategyForId(String id) => _strategyForId(id);
