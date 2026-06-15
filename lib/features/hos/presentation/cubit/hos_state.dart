part of 'hos_cubit.dart';

enum HosStatus { initial, loading, loaded, error }

class HosState extends Equatable {
  const HosState({
    this.status = HosStatus.initial,
    this.records = const [],
    this.summary,
    this.errorMessage,
  });

  final HosStatus status;
  final List<HosRecord> records;
  final HosSummary? summary;
  final String? errorMessage;

  HosState copyWith({
    HosStatus? status,
    List<HosRecord>? records,
    HosSummary? summary,
    String? errorMessage,
  }) {
    return HosState(
      status: status ?? this.status,
      records: records ?? this.records,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, summary, errorMessage];
}