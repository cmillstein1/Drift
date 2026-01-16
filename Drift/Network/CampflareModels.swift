//
//  CampflareModels.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import Foundation

// MARK: - Campground Models

struct Campground: Codable, Identifiable {
    let id: String
    let name: String
    let status: String
    let statusDescription: String?
    let kind: String
    let shortDescription: String?
    let mediumDescription: String?
    let longDescription: String?
    let location: CampgroundLocation
    let defaultCampsiteSchedule: CampsiteSchedule?
    let amenities: CampgroundAmenities?
    let maxRvLength: Double?
    let maxTrailerLength: Double?
    let hasPullThroughSites: Bool?
    let bigRigFriendly: Bool?
    let reservationUrl: String?
    let links: [CampgroundLink]?
    let photos: [CampgroundPhoto]?
    let alerts: [CampgroundAlert]?
    let price: CampgroundPrice?
    let cellService: CellService?
    let management: Management?
    let contact: Contact?
    let connections: Connections?
    let metadata: CampgroundMetadata?
}

struct CampgroundLocation: Codable {
    let latitude: Double
    let longitude: Double
    let elevation: Double?
    let address: Address?
    let directions: String?
}

struct Address: Codable {
    let street1: String?
    let street2: String?
    let city: String?
    let zipcode: String?
    let country: String?
    let countryCode: String?
    let state: String?
    let stateCode: String?
    let full: String?
}

struct CampsiteSchedule: Codable {
    let checkInTime: String?
    let checkOutTime: String?
    let uniform: Bool?
}

struct CampgroundAmenities: Codable {
    let toilets: Bool?
    let toiletKind: String?
    let trash: Bool?
    let campStore: Bool?
    let dumpStation: Bool?
    let wifi: Bool?
    let petsAllowed: Bool?
    let showers: Bool?
    let firesAllowed: Bool?
    let water: Bool?
    let electricHookups: Bool?
    let waterHookups: Bool?
    let sewerHookups: Bool?
}

struct CampgroundLink: Codable {
    let url: String
    let title: String
}

struct CampgroundPhoto: Codable {
    let originalUrl: String?
    let attributionNeeded: Bool?
    let largeUrl: String?
    let mediumUrl: String?
    let smallUrl: String?
    let attribution: String?
    let name: String?
}

struct CampgroundAlert: Codable {
    let title: String
    let content: String
    let sourceName: String?
    let sourceUrl: String?
    let startDate: String?
    let endDate: String?
}

struct CampgroundPrice: Codable {
    let minimum: Double?
    let maximum: Double?
    let currencyCode: String?
    let currency: String?
}

struct CellService: Codable {
    let verizon: Double?
    let tmobile: Double?
    let att: Double?
}

struct Management: Codable {
    let agencyName: String?
    let agencyId: String?
    let agencyWebsite: String?
}

struct Contact: Codable {
    let primaryPhone: String?
    let primaryEmail: String?
}

struct Connections: Codable {
    let ridbFacilityId: String?
    let usfsSiteId: String?
    let v1CampgroundIds: [String]?
}

struct CampgroundMetadata: Codable {
    let hasAvailabilityAlerts: Bool?
    let hasAvailabilityData: Bool?
    let hasCampsiteLevelData: Bool?
    let lastUpdated: String?
}

// MARK: - Campsite Models

struct Campsite: Codable, Identifiable {
    let id: String
    let campgroundId: String
    let name: String
    let kind: String
    let loopName: String?
    let latitude: Double?
    let longitude: Double?
    let reservationUrl: String?
    let equipment: [CampsiteEquipment]?
    let kindListed: String?
    let schedule: CampsiteSchedule?
    let price: CampsitePrice?
    let firepit: Bool?
    let picnicTable: Bool?
    let adaAccessible: Bool?
    let waterHookups: Bool?
    let electricHookups: Bool?
    let sewerHookups: Bool?
    let maxPeople: Int?
    let maxCars: Int?
    let pullThrough: Bool?
    let drivewayLength: Int?
    let maxRvLength: Int?
    let maxTrailerLength: Double?
    let photos: [CampgroundPhoto]?
}

struct CampsiteEquipment: Codable {
    let kind: String
    let name: String
}

struct CampsitePrice: Codable {
    let perNight: Double?
    let currencyCode: String?
    let currency: String?
}

// MARK: - Availability Models

struct Availability: Codable {
    let date: String
    let available: Bool
    let availableCampsites: [String]?
}

// MARK: - Search Models

struct CampgroundSearchRequest: Codable {
    let latitude: Double?
    let longitude: Double?
    let radius: Double?
    let state: String?
    let stateCode: String?
    let kind: String?
    let amenities: [String]?
    let limit: Int?
    let offset: Int?
}

struct CampgroundSearchResponse: Codable {
    let campgrounds: [Campground]
    let total: Int?
    let limit: Int?
    let offset: Int?
}
