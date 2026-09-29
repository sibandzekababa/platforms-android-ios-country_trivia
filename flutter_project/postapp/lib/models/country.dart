/// Represents a country with its name and ISO code used for flag lookup.
class Country {
  final String name;
  final String isoCode;

  const Country({required this.name, required this.isoCode});

  /// FlagCDN URL for this country's flag image.
  String get flagUrl => 'https://flagcdn.com/${isoCode.toLowerCase()}.png';

  factory Country.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as Map<String, dynamic>;
    return Country(
      name: name['common'] as String,
      isoCode: json['cca2'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          isoCode == other.isoCode;

  @override
  int get hashCode => isoCode.hashCode;

  @override
  String toString() => 'Country(name: $name, isoCode: $isoCode)';
}
