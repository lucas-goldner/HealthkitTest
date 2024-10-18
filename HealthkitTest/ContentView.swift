//
//  ContentView.swift
//  HealthkitTest
//
//  Created by Lucas Goldner on 18.10.24.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    
    // Initialize HealthStore
    let healthStore = HKHealthStore()

    // Define workout type (e.g., walking, running)
    let workoutType = HKObjectType.workoutType()

    func auth() {
        // Request authorization
        let typesToRead: Set = [workoutType, HKSeriesType.workoutRoute()]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                // Proceed with retrieving the workout
                self.retrieveLastWalkingWorkout()
            } else {
                print("Authorization failed: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }

    // Function to retrieve the last walking workout
    func retrieveLastWalkingWorkout() {
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .walking)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(),
                                  predicate: workoutPredicate,
                                  limit: 1,
                                  sortDescriptors: [sortDescriptor]) { query, results, error in
            guard let workout = results?.first as? HKWorkout else {
                print("No workout found: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            // Proceed to retrieve the route for the workout
            self.retrieveRouteForWorkout(workout)
        }
        
        healthStore.execute(query)
    }

    // Function to retrieve route data for a workout
    func retrieveRouteForWorkout(_ workout: HKWorkout) {
        let runningObjectQuery = HKQuery.predicateForObjects(from: workout)
        
        let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: runningObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
            
            guard error == nil else {
                fatalError("The initial query failed.")
            }
            // Make sure you have some route samples
            guard samples!.count > 0 else {
                return
            }
            let route = samples?.first as! HKWorkoutRoute
            
            let query = HKWorkoutRouteQuery(route: route) { (query, locationsOrNil, done, errorOrNil) in
                guard let locations = locationsOrNil else {
                    print("No locations found: \(errorOrNil?.localizedDescription ?? "unknown error")")
                    return
                }
                
                // Process the locations data
                for location in locations {
                    print("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                }
                
                if done {
                    print("All route data retrieved")
                }
            }
            healthStore.execute(query)
        }
        
        healthStore.execute(routeQuery)
    }
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button(action: auth) {
              Text("AUTH")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
