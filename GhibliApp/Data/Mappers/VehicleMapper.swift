import Foundation

enum VehicleMapper {
    static func map(dto: VehicleDTO) -> Vehicle {
        Vehicle(
            id: dto.id,
            name: dto.name,
            description: dto.description,
            vehicleClass: dto.vehicleClass,
            length: dto.length,
            pilot: dto.pilot.flatMap(URL.init(string:))
        )
    }
}
