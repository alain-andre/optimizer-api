# Copyright © Mapotempo, 2016
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require 'grape'
require 'grape-swagger'
require 'grape-entity'
require 'grape_logging'

require './optimizer_wrapper'
require './api/v01/api'

module Api
  class ApiV01 < Grape::API
    version '0.1', using: :path

    content_type :json, 'application/json; charset=UTF-8'
    content_type :xml, 'application/xml'

    mount V01::Api

    documentation_class = add_swagger_documentation(
      hide_documentation_path: true,
      consumes: [
        'application/json; charset=UTF-8',
        'application/xml',
      ],
      produces: [
        'application/json; charset=UTF-8',
        'application/xml',
      ],
      doc_version: nil,
      info: {
        title: ::OptimizerWrapper::config[:product_title],
        contact_email: ::OptimizerWrapper::config[:product_contact_email],
        contact_url: ::OptimizerWrapper::config[:product_contact_url],
        license: 'GNU Affero General Public License 3',
        license_url: 'https://raw.githubusercontent.com/Mapotempo/optimizer-api/master/LICENSE',
        description: '
## Table of Contents
* [Overview](#overview)
* [Standard Optimisation](#standard-optimisation)
  * [Input Model](#input-model)
    * [General Model](#general-model)
    * [Points](#points)
    * [TimeWindows](#timewindows)
    * [Vehicles](#vehicles)
    * [Activities](#activities)
    * [Services and Shipments](#services-and-shipments)
    * [Matrices](#matrices)
    * [Units](#units)
    * [Capacities](#capacities)
    * [Quantities](#quantities)
    * [Rests](#rests)
    * [Relations](#relations)
    * [Configuration](#configuration)
  * [Solve](#solve)
    * [Lateness¹](#lateness)
    * [Multiple Vehicles](#multiple-vehicles)
    * [Multiple Depots](#multiple-depots)
    * [Multiple Timewindows¹](#multiple-timewindows)
    * [Multiple Matrices¹](#multiple-matrices)
    * [Pickup or Delivery](#pickup-or-delivery)
    * [Priority¹](#priority)
    * [Quantities Overload¹](#quantities-overload)
    * [Setup Duration](#setup-duration)
    * [Skills](#skills)
    * [Alternative Skills³](#alternative-skills)
* [Schedule Optimisation](#schedule-optimisation)
  * [Problem Definition](#problem-definition)
  * [Vehicle Definition](#vehicle-definition)
  * [Services Definition](#services-definition)
  * [Additional Parameters](#additional-parameters)
    * [Minimum/Maximum Lapse](#min-max-lapse)
* [Zones](#zones)

-----------------
¹ Currently not available with Jsprit
² Currently not available with ORtools

-----------------

<a name="overview"></a>Overview
==

The API has been built to wrap a large panel of  Traveling Salesman Problem(TSP) and Vehicle Routing Problem(VRP) constraints in order to call the most fitted solvers.

The currently integreted solvers are:
*   **[Vroom](https://github.com/VROOM-Project/vroom)** only handle the basic Traveling Salesman Problem.
*   **[ORtools](https://github.com/google/or-tools)** handle multiple vehicles, timewindows, quantities, skills and lateness.
*   **[Jsprit](https://github.com/graphhopper/jsprit)** handle multiple vehicles, timewindows, quantities, skills and setup duration.

<a name="standard-optimisation"></a>Standard Optimisation
==

<a name="input-model"></a>Input Model
--

Before calling the solvers, a VRP model must be defined, which represent the problem to solve with all its parameters and constraints.

### <a name="general-model"></a>**General Model**
```json
"vrp": {
  "points": [..],
  "vehicles": [..],
  "units": [..],
  "services": [..],
  "shipments": [..],
  "matrices": [..],
  "rests": [..],
  "relations": [..],
  "configuration": [..]
}
```
Those high level entities are completed by few others as **timewindows** and **activities** which are locally defined.
To define the model, the first step will be to every **points** which will be used in the description of the problem. This will include the depots and the customers locations.
Furthermore at least one **vehicle** is mandatory and define at least one **service** or **shipment** will be essential to launch the solve.
The others entities are optional but will be unavoidable depending on the problem to describe.

### <a name="points"></a>**Points**
Represent a point in space, it could be called as a __location__ with latitude and longitude coordinates.
With coordinates
```json
  "points": [{
      "id": "vehicle-start",
      "location": {
        "lat": start_lat,
        "lon": start_lon
      }
    }, {
      "id": "vehicle-end",
      "location": {
        "lat": start_lat,
        "lon": start_lon
      }
    }, {
      "id": "visit-point-1",
      "location": {
        "lat": visit_lat,
        "lon": visit_lon
      }, {
      "id": "visit-point-2",
      "location": {
        "lat": visit_lat,
        "lon": visit_lon
      }
    }]
```
Or as a __matrix_index__ can be used to link to its position within the matrices.
This could be usefull if the routing data are provided from an external source.
```json
  "points": [{
      "id": "vehicle-start",
      "matrix_index": 0
    }, {
      "id": "vehicle-end",
      "matrix_index": 1
    }, {
      "id": "visit-point-1",
      "matrix_index": 2
    }, {
      "id": "visit-point-2",
      "matrix_index": 3
    }]
```
### <a name="timewindows"></a>**TimeWindows**
Define a time interval when a resource is available or when an activity can begin. By default duration are supposed to be defined in seconds. If a time matrix is send with the problem, values must be set on the same time unit.
Vehicles only have single timewindow
```json
  "timewindow": {
    "start": 0,
    "end": 7200
  }
```
Activities can have multiple timewindows
```json
  "timewindows": [{
    "start": 600,
    "end": 900
  },{
    "start": 1200,
    "end": 1500
  }],
```
### <a name="vehicles"></a>**Vehicles**
Describe the features of the existing or supposed vehicles. It should be taken in every sense, it could represent a work day of a particular driver/vehicle, or a planning over long period of time. It represents the entity which must travel between points.
```json
  "vehicles": [{
    "id": "vehicle_id",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "timewindow": {
      "start": 0,
      "end": 7200
    },
    "start_point_id": "vehicle-start",
    "end_point_id": "vehicle-end"
  }]
```
Costs can also be added in order to fit more precisely the real operating cost
```json
  "vehicles": [{
    "id": "vehicle_id",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "timewindow": {
      "start": 0,
      "end": 7200
    },
    "start_point_id": "vehicle-start",
    "end_point_id": "vehicle-end",
    "cost_fixed": 500.0,
    "cost_distance_multiplier": 1.0,
    "cost_time_multiplier": 1.0
  }]
```
The router dimension can be set as distance, this describe that the route between will be the shortest, instead of the fastest.
```json
  "vehicles": [{
    "id": "vehicle_id",
    "router_mode": "car",
    "router_dimension": "distance",
    "speed_multiplier": 1.0,
    "timewindow": {
      "start": 0,
      "end": 7200
    },
    "start_point_id": "vehicle-start",
    "end_point_id": "vehicle-end",
    "cost_fixed": 500.0,
    "cost_distance_multiplier": 1.0,
    "cost_time_multiplier": 0.0
  }]
```

### <a name="activities"></a>**Activities**
Describe where an activity take place, when it can be performed and how long it last.
```json
  "activity": {
    "point_id": "visit-point",
    "timewindows": [{
      "start": 3600,
      "end": 4800
    }],
    "duration": 2100.0
  }
```
### <a name="services-and-shipments"></a>**Services and Shipments**
Describe more specifically the activities to be performed.
Services are single activities which are self-sufficient.
```json
  "services": [{
    "id": "visit",
    "type": "service",
    "activity": {
      "point_id": "visit-point-1",
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }],
      "duration": 2100.0
    }
  }
```
Shipments are a couple of indivisible activities, the __pickup__ is the action which must take-off a package and the __delivery__ the action which deliver this particular package.
__pickup__ and __delivery__ are build following the __activity__ model
```json
  "shipments": [{
    "id": "shipment",
    "pickup": {
      "point_id": "visit-point-1",
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }]
    },
    "delivery": {
      "point_id": "visit-point-2",
      "duration": 2100.0
    }
  }]
```
### <a name="matrices"></a>**Matrices**
Describe the topology of the problem, it represent travel time, distance or value between every points,
Matrices are not mandatory, if time or distance are not defined the router wrapper will use the points data to build it.
```json
  "matrices": [{
    "id": "matrix-1",
    "time": [
      [0, 655, 1948, 5231],
      [603, 0, 1692, 4977],
      [1861, 1636, 0, 6143],
      [5184, 4951, 6221, 0]
    ]
  }]
```
With this matrix defined, the vehicle definition is now the following :
```json
  "vehicles": [{
    "id": "vehicle_id",
    "matrix_id": "matrix-1",
    "start_point_id": "vehicle-start",
    "end_point_id": "vehicle-end",
    "timewindow": {
      "start": 0,
      "end": 7200
    },
    "cost_fixed": 0.0,
    "cost_distance_multiplier": 0.0,
    "cost_time_multiplier": 1.0
  }]
```
Note that every vehicle could be linked to different matrices in order to model multiple transport mode

In the case the distance cost is greater than 0, it will be mandatory to transmit the related matrix
```json
  "matrices": [{
    "id": "matrix-1",
    "time": [
      [0, 655, 1948, 5231],
      [603, 0, 1692, 4977],
      [1861, 1636, 0, 6143],
      [5184, 4951, 6221, 0]
    ],
    "distance": [
      [0, 655, 1948, 5231],
      [603, 0, 1692, 4977],
      [1861, 1636, 0, 6143],
      [5184, 4951, 6221, 0]
    ]
  }]
```
Whenever there is no time constraint and the objective is only set on distance, the time matrix is not mandatory
### <a name="units"></a>**Units**
Describe the dimension used for the goods. ie : kgs, litres, pallets...etc
```json
  "units": [{
    "id": "unit-Kg",
    "label": "Kilogram"
  }]
```
### <a name="capacities"></a>**Capacities**
Define the limit allowed for a defined unit into the vehicle.
```json
  "capacities": [{
    "unit_id": "unit-Kg",
    "limit": 10,
    "overload_multiplier": 0
  }]
```
Which is defined as follows
```json
  "vehicles": [{
    "id": "vehicle_id",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "timewindow": {
      "start": 0,
      "end": 7200
    },
    "capacities": [{
      "unit_id": "unit-Kg",
      "limit": 10,
      "overload_multiplier": 0
    }],
    "start_point_id": "vehicle-start",
    "end_point_id": "vehicle-end",
    "cost_fixed": 0.0,
    "cost_distance_multiplier": 0.0,
    "cost_time_multiplier": 1.0
  }]
```
### <a name="quantities"></a>**Quantities**
Inform of the package size, shift within a route once loaded into a vehicle.
```json
  "quantities": [{
    "unit_id": "unit-Kg",
    "value": 8
  }]
```
```json
  "services": [{
    "id": "visit",
    "type": "service",
    "activity": {
      "point_id": "visit-point-1",
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }],
      "duration": 2100.0
    },
    "quantities": [{
      "unit_id": "unit-Kg",
      "value": 8
    }]
  }
```
```json
  "shipments": [{
    "id": "pickup_delivery",
    "pickup": {
      "point_id": "visit-point-1",
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }],
      "duration": 2100.0
    },
    "delivery": {
      "point_id": "visit-point-2",
      "timewindows": [{
        "start": 4500,
        "end": 7200
      }],
      "duration": 1100.0
    },
    "quantities": [{
      "unit_id": "unit-Kg",
      "value": 8
    }]
  }
```
### <a name="rests"></a>**Rests**
Inform about the drivers obligations to have some rest within a route
```json
  "rests": [{
    "id": "Break-1",
    "timewindows": [{
      "start": 1200,
      "end": 2400
    }],
    "duration": 600
  }]
```

```json
  "vehicles": [{
    "id": "vehicle_id",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "timewindow": {
      "start": 0,
      "end": 7200
    },
    "rests_ids": ["Break-1"]
    "start_point_id": "vehicle-start",
    "end_point_id": "vehicle-end",
    "cost_fixed": 0.0,
    "cost_distance_multiplier": 0.0,
    "cost_time_multiplier": 1.0
  }]
```

### <a name="relations"></a>**Relations**
Relations allow to define constraints explicitly between missions.
Those could be of the following types: 
  * **same_route** : force missions to be served within the same route.
  * **order** : force services to be served within the same route in a specific order, but allow to insert others missions between
  * **sequence** : force services to be served in a specific order, excluding others missions to be performed between
  * **meetup** : ensure that some missions are performed at the same time by multiple vehicles.

```json
  "relations": [{
    "id": "sequence_1",
    "type": "sequence",
    "linked_ids": ["service_1", "service_3", "service_2"]
  }]
```


### <a name="configuration"></a>**Configuration**
The configuration is divided in four parts
Preprocessing parameters will twist the problem in order to simplify or orient the solve
```json
  "configuration": {
    "preprocessing": {
      "cluster_threshold": 5,
      "prefer_short_segment": true
    }
  }
```
Resolution parameters will only indicate when stopping the search is admissible
```json
  "configuration": {
    "resolution": {
      "duration": 30,
      "iterations": 1000,
      "iterations_without_improvment": 100
    }
  }
```
**VROOM** requires no parameters and stops by itself.
**ORtools** Can take a maximum solve duration, or can stop by itself depending on the solve state as a time-out between two new best solution, or as a number of iterations without improvement.
**Jsprit**: Can take a maximum solve duration, a number of iterations wihtout improvment or a number of iteration without variation in the neighborhood search.

Schedule parameters are only usefull in the case of Schedule Optimisation. Those allow to define the considerated period (__range_indices__) and the indices which are unavailable within the solve (__unavailable_indices__)
```json
  "configuration": {
    "schedule": {
      "range_indices": {
        "start": 0,
        "end": 13
      },
      "unavailable_indices": [5, 6, 12, 13]
    }
  }
```
An alternative exist to those parameters in order to define it by date instead of indices __schedule_range_date__ and __schedule_unavailable_date__.

Restitution parameters allow to have some control on the API response
```json
  "configuration": {
    "restitution": {
      "geometry": true,
      "geometry_polyline": false
    }
  }
```
__geometry__ inform the API to return the Geojson of the route in output
__geometry_polyline__ precise that the geojson must be an encoded polyline.

 <a name="solve"></a>Solve
--
The current API can handle multiple particular behavior.
### <a name="lateness"></a>Lateness¹
Once defined at the service level it allow the vehicles to arrive late at a points to serve.
```json
  "services": [{
    "id": "visit",
    "type": "service",
    "activity": {
      "point_id": "visit-point-1",
      "late_multiplier": 0.3,
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }],
      "duration": 2100.0
    }
  }
```
Defined at the vehicle level, it allow the vehicle to arrive late at the ending depot.
```json
  "vehicles": [{
    "id": "vehicle_id-1",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "timewindow": {
      "start": 0,
      "end": 7200
    },
    "start_point_id": "vehicle-start-1",
    "end_point_id": "vehicle-start-1",
    "cost_fixed": 500.0,
    "cost_late_multiplier", 0.3,
    "cost_distance_multiplier": 1.0,
    "cost_time_multiplier": 1.0
  }]
```
Note : In the case of a global optimization, at least one those two parameters (__late_multiplier__ or __cost_late_multiplier__) must be set to zero, otherwise only one vehicle would be used.
### <a name="multiple-vehicles"></a>Multiple vehicles
```json
  "vehicles": [{
    "id": "vehicle_id-1",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "timewindow": {
      "start": 0,
      "end": 7200
    },
    "start_point_id": "vehicle-start",
    "end_point_id": "vehicle-end",
    "cost_fixed": 500.0,
    "cost_distance_multiplier": 1.0,
    "cost_time_multiplier": 1.0
  },{
    "id": "vehicle_id-2",
    "router_mode": "truck",
    "router_dimension": "distance",
    "speed_multiplier": 0.9,
    "timewindow": {
      "start": 8900,
      "end": 14400
    },
    "start_point_id": "vehicle-start",
    "end_point_id": "vehicle-end",
    "cost_fixed": 4000.0,
    "cost_distance_multiplier": 0.60,
    "cost_time_multiplier": 0
  }]
```
### <a name="multiple-depots"></a>Multiple depots
Depots can be set to any points or stay free (in such case don\'t send the associated key word)
```json
  "vehicles": [{
    "id": "vehicle_id-1",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "start_point_id": "vehicle-start-1",
    "end_point_id": "vehicle-start-1",
    "cost_fixed": 500.0,
    "cost_distance_multiplier": 1.0,
    "cost_time_multiplier": 1.0
  }, {
    "id": "vehicle_id-2",
    "router_mode": "truck",
    "router_dimension": "distance",
    "speed_multiplier": 0.9,
    "start_point_id": "vehicle-start-2",
    "end_point_id": "vehicle-end-2",
    "cost_fixed": 4000.0,
    "cost_distance_multiplier": 0.60,
    "cost_time_multiplier": 0
  }, {
    "id": "vehicle_id-2",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "end_point_id": "vehicle-end-2",
    "cost_fixed": 500.0,
    "cost_distance_multiplier": 1.0,
    "cost_time_multiplier": 1.0
  }]
```
### <a name="multiple-matrices"></a>Multiple matrices¹
Every vehicle can have its own matrix to represent its custom speed or route behavior.
```json
  "matrices": [{
    "id": "matrix-1",
    "time": [
      [0, 655, 1948, 5231],
      [603, 0, 1692, 4977],
      [1861, 1636, 0, 6143],
      [5184, 4951, 6221, 0]
    ]
  }, {
    "id": "matrix-2",
    "time": [
      [0, 541, 1645, 4800],
      [530, 0, 1503, 4465],
      [1506, 1298, 0, 5836],
      [4783, 4326, 5760, 0]
    ]
  }]
```
### <a name="multiple-timewindows"></a>Multiple TimeWindows
```json
  "services": [{
    "id": "visit",
    "type": "service",
    "activity": {
      "point_id": "visit-point-1",
      "timewindows": [{
        "start": 1200,
        "end": 2400
      }, {
        "start": 3600,
        "end": 4800
      }],
      "duration": 2100.0
    }
  }
```
### <a name="pickup-or-delivery"></a>Pickup or Delivery
Services can be set with a __pickup__ or a __delivery__ type which inform the solver about the activity to perform. The __pickup__ allows a reload action within the route, the __delivery__ allows to drop off resources.
```json
  "services": [{
    "id": "visit-pickup",
    "type": "pickup",
    "activity": {
      "point_id": "visit-point-1",
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }],
      "duration": 2100.0
    },
    "quantities": [{
      "unit_id": "unit-Kg",
      "value": 8
    }]
  }, {
    "id": "visit-delivery",
    "type": "delivery",
    "activity": {
      "point_id": "visit-point-2",
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }],
      "duration": 2100.0
    },
    "quantities": [{
      "unit_id": "unit-Kg",
      "value": 6
    }]
  }]
```
### <a name="priority"></a>Priority¹
Indicate to the solver which activities are the most important, the priority 0 is two times more important than a priority 1 which is itself two times more important than a priority 2 and so on until the priority 8.
```json
 "services": [{
    "id": "visit-1",
    "type": "service",
    "activity": {
      "point_id": "visit-point-1",
      "late_multiplier": 0.3,
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }],
      "duration": 600.0,
      "priority": 0
    }
  }, {
    "id": "visit-2",
    "type": "service",
    "activity": {
      "point_id": "visit-point-1",
      "late_multiplier": 0.3,
      "timewindows": [{
        "start": 3800,
        "end": 5000
      }],
      "duration": 600.0,
      "priority": 2
    }
  }]
```
### <a name="quantities-overload"></a>Quantities overload¹
Allow the vehicles to load more than the defined limit, but add a cost at every excess unit.
```json
  "vehicles": [{
    "id": "vehicle_id",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "capacities": [{
      "unit_id": "unit-Kg",
      "limit": 10,
      "overload_multiplier": 0.3
    }],
    "start_point_id": "vehicle-start",
    "end_point_id": "vehicle-end",
    "cost_fixed": 0.0,
    "cost_distance_multiplier": 0.0,
    "cost_time_multiplier": 1.0
  }]
```
### <a name="setup-duration"></a>Setup duration
When multiple activities are performed at the same location in a direct sequence it allows to have a common time of preparation. It Could be assimilated to an administrative time.
```json
 "services": [{
    "id": "visit-1",
    "type": "service",
    "activity": {
      "point_id": "visit-point-1",
      "late_multiplier": 0.3,
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }],
      "duration": 600.0,
      "setup_duration": 1500.0
    }
  }, {
    "id": "visit-2",
    "type": "service",
    "activity": {
      "point_id": "visit-point-1",
      "late_multiplier": 0.3,
      "timewindows": [{
        "start": 3800,
        "end": 5000
      }],
      "duration": 600.0,
      "setup_duration": 1500.0
    }
  }]
```
If those two services are performed in a row, the cumulated time of activity will be : 1500 + 600 + 600 = 2700 instead of 4200 if the two duration were set to 2100.
### <a name="skills"></a>Skills
Some package must be carried by some particular vehicle, or some points can only be visited by some particular vehicle or driver. Skills allow to represent those kind of constraints.  
A vehicle can carry the __services__ or __shipments__ with the defined __skills__ and the ones which have none or part of the current vehicle skills.
```json
  "vehicles": [{
    "id": "vehicle_id",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "start_point_id": "vehicle-start",
    "end_point_id": "vehicle-end",
    "skills": [
        ["frozen"]
      ]
    "cost_fixed": 0.0,
    "cost_distance_multiplier": 0.0,
    "cost_time_multiplier": 1.0
  }]
```
Missions must be carried by a vehicle which have at least all the required skills by the current service or shipment.
```json
  "services": [{
    "id": "visit",
    "type": "service",
    "activity": {
      "point_id": "visit-point-1",
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }],
      "duration": 2100.0
    },
    "skills": ["frozen"]
  }
```
### <a name="alternative-skills"></a>Alternative Skills³
Some vehicles can change its __skills__ once empty, passing from one configuration to another. Here passing from a configuration it can carry only cool products from another it can only tool frozen ones and vice versa.
```json
  "vehicles": [{
    "id": "vehicle_id",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "start_point_id": "vehicle-start",
    "end_point_id": "vehicle-end",
    "skills": [
        ["cool"],
        ["frozen"]
      ]
    "cost_fixed": 0.0,
    "cost_distance_multiplier": 0.0,
    "cost_time_multiplier": 1.0
  }]
```
```json
  "services": [{
    "id": "visit-1",
    "type": "service",
    "activity": {
      "point_id": "visit-point-1",
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }],
      "duration": 2100.0
    },
    "skills": ["frozen"]
  }, {
    "id": "visit-2",
    "type": "service",
    "activity": {
      "point_id": "visit-point-2",
      "timewindows": [{
        "start": 3600,
        "end": 4800
      }],
      "duration": 2100.0
    },
    "skills": ["cool"]
  }]
```

<a name="schedule-optimisation"></a>Schedule Optimisation
==

<a name="problem-definition"></a>Problem definition
---

The plan must be described in its general way, the schedule duration the begin and end days or indices.
Some day may have to be exclude from the resolution, like holiday, and could be defined by its days or indices.
```json
  "configuration": {
      "preprocessing": {
          "prefer_short_segment": true
      },
      "resolution": {
          "duration": 1000,
          "iterations_without_improvment": 100
      },
      "schedule": {
          "range_indices": {
              "start": 0,
              "end": 13
          },
          "unavailable_indices": [2]
      }
  }

```

<a name="vehicle-definition"></a>Vehicle definition
---

The timewindows of a vehicle over a week can be defined with an array using __sequence_timewindows__ instead of a single timewindow.
To link a timewindow with a week day, a __day_index can__ be set (from 0 [monday] to 6 [sunday]). Those time slot will repeated over the entire period for every week contained.
As at the problem definition level, some days could be unavailable to a specific vehicle, this can be defined with __unavailable_work_date__ or __unavailable_work_day_indices__
```json
  {
    "id": "vehicle_id-1",
    "router_mode": "car",
    "router_dimension": "time",
    "speed_multiplier": 1.0,
    "sequence_timewindows": [{
        "day_index": 0,
        "start": 25200,
        "end": 57600
    }, {
        "day_index": 1,
        "start": 25200,
        "end": 57600
    }, {
        "day_index": 2,
        "start": 25200,
        "end": 57600
    }, {
        "day_index": 3,
        "start": 25200,
        "end": 57600
    }, {
        "day_index": 4,
        "start": 25200,
        "end": 57600
    }],
    "start_point_id": "store",
    "end_point_id": "store",
    "unavailable_work_day_indices": [5, 7]
  }
```

<a name="services-definition"></a>Services definition
---

As the vehicles, services have period defined timewindows, using __day_index__ parameter within its timewindows. And some days could be not available to deliver a customer, which can be defined with __unavailable_visit_day_indices__ or __unavailable_visit_day_date__
Some visits could be avoided because it is not mandatory, or any particular reason, __unavailable_visit_indices__ allow to not include a particular visit over the period.
To define multiple visit of a customer over the period, you can set it through the __visits_number__ field.
By default, it will divide the period by the number of visits in order to non overlap the multiple visits.
```json
  {
    "id": "visit-1",
    "type": "service",
    "activity": {
        "point_id": "visit-point-1",
        "timewindows": [{
            "day_index": 0,
            "start": 28800,
            "end": 64800
        }, {
            "day_index": 0,
            "start": 61200,
            "end": 97200
        }, {
            "day_index": 2,
            "start": 28800,
            "end": 64800
        }, {
            "day_index": 3,
            "start": 28800,
            "end": 64800
        }, {
            "day_index": 4,
            "start": 28800,
            "end": 64800
        }],
        "duration": 1200.0
    },
    "visits_number": 2
  }
```
N.B: Shipments are currently not available within the schedule optimisation

<a name="additional-parameters"></a>Additional parameters
---

### <a name="min-max-lapse"></a>**Minimum/Maximum Lapse**
Between to visits of the same mission, it could be necessary to determine exactly the lapse. At this purpose, the __minimum_lapse__ and __maximum_lapse__ fields of services are available.
```json
  {
    "id": "visit-1",
    "type": "service",
    "activity": {
        "point_id": "visit-point-1",
        "timewindows": [{
            "day_index": 0,
            "start": 28800,
            "end": 64800
        }, {
            "day_index": 0,
            "start": 61200,
            "end": 97200
        }, {
            "day_index": 2,
            "start": 28800,
            "end": 64800
        }, {
            "day_index": 3,
            "start": 28800,
            "end": 64800
        }, {
            "day_index": 4,
            "start": 28800,
            "end": 64800
        }],
        "duration": 1200.0
    },
    "visits_number": 2,
    "minimum_lapse": 7,
    "maximum_lapse": 14
  }
```

<a name="zones"></a>Zones
==

In order to distribute geographically the problem, some sector can be defined. The API takes geojson and encrypted geojson. A zone contains the vehicles which are allowed to perform it at the same time. The API call make it feasible to have multiple elaborate combinations.
But only a single complex combination (multiple vehicles allowed to perform activities within the area at the same time).
```json
      "zones": [{
        "id": "zone_0",
        "polygon": {
        "type": "Polygon",
        "coordinates": [[[0.5,48.5],[1.5,48.5],[1.5,49.5],[0.5,49.5],[0.5,48.5]]]
        },
        "allocations": [["vehicle_0", "vehicle_1"]]
      }]
```
Or multiple unique vehicle alternative are currently implemented at the solver side.
```json
      "zones": [{
        "id": "zone_0",
        "polygon": {
        "type": "Polygon",
        "coordinates": [[[0.5,48.5],[1.5,48.5],[1.5,49.5],[0.5,49.5],[0.5,48.5]]]
        },
        "allocations": [["vehicle_0"], ["vehicle_1"]]
      }]
```
'
      }
    )
  end
end
