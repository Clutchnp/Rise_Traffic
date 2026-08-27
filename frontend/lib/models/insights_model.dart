class InsightsResponse {
  final List<TemporalFlowEntry> temporalFlowChart;
  final List<HotspotEntry> topHotspotsChart;
  final List<AccidentProneEntry> accidentProneChart;

  InsightsResponse({
    required this.temporalFlowChart,
    required this.topHotspotsChart,
    required this.accidentProneChart,
  });

  factory InsightsResponse.fromJson(Map<String, dynamic> json) {
    return InsightsResponse(
      temporalFlowChart: (json['temporal_flow_chart'] as List)
          .map((i) => TemporalFlowEntry.fromJson(i))
          .toList(),
      topHotspotsChart: (json['top_hotspots_chart'] as List)
          .map((i) => HotspotEntry.fromJson(i))
          .toList(),
      accidentProneChart: (json['accident_prone_chart'] as List)
          .map((i) => AccidentProneEntry.fromJson(i))
          .toList(),
    );
  }
}

class TemporalFlowEntry {
  final String timeLabel;
  final int avgVolume;

  TemporalFlowEntry({required this.timeLabel, required this.avgVolume});

  factory TemporalFlowEntry.fromJson(Map<String, dynamic> json) {
    return TemporalFlowEntry(
      timeLabel: json['time_label'],
      avgVolume: json['avg_volume'],
    );
  }
}

class HotspotEntry {
  final String locationName;
  final int avgVolume;

  HotspotEntry({required this.locationName, required this.avgVolume});

  factory HotspotEntry.fromJson(Map<String, dynamic> json) {
    return HotspotEntry(
      locationName: json['location_name'],
      avgVolume: json['avg_volume'],
    );
  }
}

class AccidentProneEntry {
  final String locationName;
  final int accidentCount;

  AccidentProneEntry({required this.locationName, required this.accidentCount});

  factory AccidentProneEntry.fromJson(Map<String, dynamic> json) {
    return AccidentProneEntry(
      locationName: json['location_name'],
      accidentCount: json['accident_count'],
    );
  }
}
