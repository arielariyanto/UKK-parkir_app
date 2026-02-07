class Area {
  final int? idArea;
  final String namaArea;
  final int kapasitas;
  final int terisi;

  Area({
    this.idArea,
    required this.namaArea,
    required this.kapasitas,
    this.terisi = 0,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      idArea: json['id_area'] is int ? json['id_area'] : (json['id_area'] != null ? int.tryParse(json['id_area'].toString()) : null),
      namaArea: json['nama_area']?.toString() ?? '',
      kapasitas: json['kapasitas'] is int ? json['kapasitas'] : (json['kapasitas'] != null ? int.tryParse(json['kapasitas'].toString()) ?? 0 : 0),
      terisi: json['terisi'] is int ? json['terisi'] : (json['terisi'] != null ? int.tryParse(json['terisi'].toString()) ?? 0 : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idArea != null) 'id_area': idArea,
      'nama_area': namaArea,
      'kapasitas': kapasitas,
      'terisi': terisi,
    };
  }

  int get tersedia => kapasitas - terisi;
}
