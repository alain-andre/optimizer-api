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
require './test/test_helper'

class WrapperTest < Minitest::Test

  def test_zip_cluster
    size = 5
    problem = {
      matrices: {
        time: [
          [ 0,  1,  1, 10,  0],
          [ 1,  0,  1, 10,  1],
          [ 1,  1,  0, 10,  1],
          [10, 10, 10,  0, 10],
          [ 0,  1,  1, 10,  0]
        ],
        distance: [
          [ 0,  1,  1, 10,  0],
          [ 1,  0,  1, 10,  1],
          [ 1,  1,  0, 10,  1],
          [10, 10, 10,  0, 10],
          [ 0,  1,  1, 10,  0]
        ]
      },
      points: (0..(size - 1)).collect{ |i|
        {
          id: "point_#{i}",
          matrix_index: i
        }
      },
      services: (1..(size - 1)).collect{ |i|
        {
          id: "service_#{i}",
          activity: {
            point_id: "point_#{i}",
            timewindows: [{
              start: 1,
              end: 2
            }]
          },
          skills: ['A']
        }
      },
      rests: [{
        id: 'rest_0',
        timewindows: [{
          start: 1,
          end: 1
        }],
        duration: 1
      }],
      vehicles: [{
        id: 'vehicle_0',
        start_point_id: 'point_0',
        rest_ids: ['rest_0']
      }],
      configuration: {
        preprocessing: {
          cluster_threshold: 5
        },
        resolution: {
          duration: 10
        }
      }
    }
    assert_equal 2, OptimizerWrapper.send(:zip_cluster, Models::Vrp.create(problem), 5).size # without start/end/rest
  end

  def test_no_zip_cluster
    size = 5
    problem = {
      matrices: {
        time: [
          [ 0, 10, 20, 30,  0],
          [10,  0, 30, 40, 10],
          [20, 30,  0, 50, 20],
          [30, 40, 50,  0, 30],
          [ 0, 10, 20, 30,  0]
        ],
        distance: [
          [ 0, 10, 20, 30,  0],
          [10,  0, 30, 40, 10],
          [20, 30,  0, 50, 20],
          [30, 40, 50,  0, 30],
          [ 0, 10, 20, 30,  0]
        ]
      },
      points: (0..(size - 1)).collect{ |i|
        {
          id: "point_#{i}",
          matrix_index: i
        }
      },
      services: (1..(size - 1)).collect{ |i|
        {
          id: "service_#{i}",
          activity: {
            point_id: "point_#{i}"
          }
        }
      },
      vehicles: [{
        id: 'vehicle_0',
        start_point_id: 'point_0'
      }],
      configuration: {
        preprocessing: {
          cluster_threshold: 5
        },
        resolution: {
          duration: 10
        }
      }
    }
    assert_equal 4, OptimizerWrapper.send(:zip_cluster, Models::Vrp.create(problem), 5).size # without start/end/rest
  end

  def test_no_zip_cluster_tws
    size = 5
    problem = {
      matrices: {
        time: [
          [ 0,  1,  1, 10,  0],
          [ 1,  0,  1, 10,  1],
          [ 1,  1,  0, 10,  1],
          [10, 10, 10,  0, 10],
          [ 0,  1,  1, 10,  0]
        ],
        distance: [
          [ 0,  1,  1, 10,  0],
          [ 1,  0,  1, 10,  1],
          [ 1,  1,  0, 10,  1],
          [10, 10, 10,  0, 10],
          [ 0,  1,  1, 10,  0]
        ]
      },
      points: (0..(size - 1)).collect{ |i|
        {
          id: "point_#{i}",
          matrix_index: i
        }
      },
      services: (1..(size - 1)).collect{ |i|
        {
          id: "service_#{i}",
          activity: {
            point_id: "point_#{i}",
            timewindows: [{
              start: 1,
              end: 2
            }],
            duration: 1
          }
        }
      },
      rests: [{
        id: 'rest_0',
        timewindows: [{
          start: 1,
          end: 1
        }],
        duration: 1
      }],
      vehicles: [{
        id: 'vehicle_0',
        start_point_id: 'point_0',
        rest_ids: ['rest_0']
      }],
      configuration: {
        preprocessing: {
          cluster_threshold: 5
        },
        resolution: {
          duration: 10
        }
      }
    }
    assert_equal 4, OptimizerWrapper.send(:zip_cluster, Models::Vrp.create(problem), 5).size # without start/end/rest
  end

  def test_no_zip_cluster_with_multiple_vehicles
    size = 5
    problem = {
      matrices: {
        time: [
          [ 0,  1,  1, 10,  0],
          [ 1,  0,  1, 10,  1],
          [ 1,  1,  0, 10,  1],
          [10, 10, 10,  0, 10],
          [ 0,  1,  1, 10,  0]
        ],
        distance: [
          [ 0,  1,  1, 10,  0],
          [ 1,  0,  1, 10,  1],
          [ 1,  1,  0, 10,  1],
          [10, 10, 10,  0, 10],
          [ 0,  1,  1, 10,  0]
        ]
      },
      points: (0..(size - 1)).collect{ |i|
        {
          id: "point_#{i}",
          matrix_index: i
        }
      },
      services: (1..(size - 1)).collect{ |i|
        {
          id: "service_#{i}",
          activity: {
            point_id: "point_#{i}"
          }
        }
      },
      vehicles: [{
        id: 'vehicle_0',
        start_point_id: 'point_0'
      }, {
        id: 'vehicle_1',
        start_point_id: 'point_0'
      }],
      configuration: {
        preprocessing: {
          cluster_threshold: 5
        },
        resolution: {
          duration: 10
        }
      }
    }
    assert_nil OptimizerWrapper.send(:zip_cluster, Models::Vrp.create(problem), 5)
  end

  def test_zip_cluster_with_real_matrix
    size = 6
    problem = {
      matrices: {
        time: [
          [0, 693, 655, 1948, 693, 0],
          [609, 0, 416, 2070, 0, 609],
          [603, 489, 0, 1692, 489, 603],
          [1861, 1933, 1636, 0, 1933, 1861],
          [609, 0, 416, 2070, 0, 609],
          [0, 693, 655, 1948, 693, 0]
        ]
      },
      points: (0..(size - 1)).collect{ |i|
        {
          id: "point_#{i}",
          matrix_index: i
        }
      },
      services: (1..(size - 2)).collect{ |i|
        {
          id: "service_#{i}",
          activity: {
            point_id: "point_#{i}",
            timewindows: [{
              start: 1,
              end: 2
            }],
            duration: 0
          },
          skills: ['A']
        }
      },
      vehicles: [{
        id: 'vehicle_0',
        start_point_id: 'point_0',
        end_point_id: 'point_' + (size - 1).to_s
      }],
      configuration: {
        preprocessing: {
          cluster_threshold: 5
        },
        resolution: {
          duration: 10
        }
      }
    }
    assert_equal 3, OptimizerWrapper.send(:zip_cluster, Models::Vrp.create(problem), 5).size # without start/end/rest
  end

  def test_no_zip_cluster_with_real_matrix
    size = 6
    problem = {
      matrices: {
        time: [
          [0, 655, 1948, 5231, 2971, 0],
          [603, 0, 1692, 4977, 2715, 603],
          [1861, 1636, 0, 6143, 1532, 1861],
          [5184, 4951, 6221, 0, 7244, 5184],
          [2982, 2758, 1652, 7264, 0, 2982],
          [0, 655, 1948, 5231, 2971, 0]
        ]
      },
      points: (0..(size - 1)).collect{ |i|
        {
          id: "point_#{i}",
          matrix_index: i
        }
      },
      services: (1..(size - 2)).collect{ |i|
        {
          id: "service_#{i}",
          activity: {
            point_id: "point_#{i}"
          }
        }
      },
      vehicles: [{
        id: 'vehicle_0',
        start_point_id: 'point_0',
        end_point_id: 'point_' + (size - 1).to_s
      }],
      configuration: {
        preprocessing: {
          cluster_threshold: 5
        },
        resolution: {
          duration: 10
        }
      }
    }
    assert_equal 4, OptimizerWrapper.send(:zip_cluster, Models::Vrp.create(problem), 5).size # without start/end/rest
  end

  def test_with_cluster
    size = 5
    problem = {
      matrices: {
        time: [
          [ 0,  1,  1, 10,  0],
          [ 1,  0,  1, 10,  1],
          [ 1,  1,  0, 10,  1],
          [10, 10, 10,  0, 10],
          [ 0,  1,  1, 10,  0]
        ],
        distance: [
          [ 0,  1,  1, 10,  0],
          [ 1,  0,  1, 10,  1],
          [ 1,  1,  0, 10,  1],
          [10, 10, 10,  0, 10],
          [ 0,  1,  1, 10,  0]
        ]
      },
      points: (0..(size - 1)).collect{ |i|
        {
          id: "point_#{i}",
          matrix_index: i
        }
      },
      services: (1..(size - 1)).collect{ |i|
        {
          id: "service_#{i}",
          activity: {
            point_id: "point_#{i}"
          }
        }
      },
      vehicles: [{
        id: 'vehicle_0',
        start_point_id: 'point_0'
      }],
      configuration: {
        preprocessing: {
          cluster_threshold: 5
        },
        resolution: {
          duration: 10
        }
      }
    }
    vrp = Models::Vrp.create(problem)
    [:ortools, :jsprit, :vroom].each{ |o|
      result = OptimizerWrapper.solve(o, vrp)
      assert_equal size + 1, result[:routes][0][:activities].size, "[#{o}] " # always return activities for start/end
      services = result[:routes][0][:activities].collect{ |a| a[:service_id] }
      (size - 1).times.each{ |i|
        assert_includes services, "service_#{i + 1}", "[#{o}] Service missing: #{i + 1}"
      }
      points = result[:routes][0][:activities].collect{ |a| a[:point_id] }
      assert_includes points, "point_0", "[#{o}] Point missing: 0"
      assert_includes points, "point_#{size - 2}", "[#{o}] Point missing: #{size - 1}"
    }
  end

  def test_with_large_size_cluster
    size = 9
    problem = {
      matrices: {
        time: [
          [0, 1, 2, 3, 4, 5, 6, 7, 8],
          [1, 0, 2, 3, 4, 5, 6, 7, 8],
          [1, 2, 0, 3, 4, 5, 6, 7, 8],
          [1, 2, 3, 0, 4, 5, 6, 7, 8],
          [1, 2, 3, 4, 0, 5, 6, 7, 8],
          [1, 2, 3, 4, 5, 0, 6, 7, 8],
          [1, 2, 3, 4, 5, 6, 0, 7, 8],
          [1, 2, 3, 4, 5, 6, 7, 0, 8],
          [1, 2, 3, 4, 5, 6, 7, 8, 0]
        ],
        distance: [
          [0, 1, 2, 3, 4, 5, 6, 7, 8],
          [1, 0, 2, 3, 4, 5, 6, 7, 8],
          [1, 2, 0, 3, 4, 5, 6, 7, 8],
          [1, 2, 3, 0, 4, 5, 6, 7, 8],
          [1, 2, 3, 4, 0, 5, 6, 7, 8],
          [1, 2, 3, 4, 5, 0, 6, 7, 8],
          [1, 2, 3, 4, 5, 6, 0, 7, 8],
          [1, 2, 3, 4, 5, 6, 7, 0, 8],
          [1, 2, 3, 4, 5, 6, 7, 8, 0]
        ]
      },
      points: (0..(size - 1)).collect{ |i|
        {
          id: "point_#{i}",
          matrix_index: i
        }
      },
      services: (1..(size - 2)).collect{ |i|
        {
          id: "service_#{i}",
          activity: {
            point_id: "point_#{i}",
            timewindows: [{
              start: 1,
              end: 2
            }]
          },
          skills: ['A']
        }
      },
      rests: [{
        id: 'rest_0',
        timewindows: [{
          start: 1,
          end: 1
        }],
        duration: 1
      }],
      vehicles: [{
        id: 'vehicle_0',
        start_point_id: 'point_0',
        end_point_id: 'point_' + (size - 1).to_s,
        rest_ids: ['rest_0']
      }],
      configuration: {
        preprocessing: {
          cluster_threshold: 6
        },
        resolution: {
          duration: 10
        }
      }
    }
    original_stdout = $stdout
    $stdout = StringIO.new('','w')
    result = OptimizerWrapper.solve(:ortools, Models::Vrp.create(problem))
    traces = $stdout.string
    $stdout = original_stdout
    assert_match /> iter /, traces, "Missing /> iter / in:\n " + traces
    assert_equal size + 1, result[:routes][0][:activities].size # always return activities for start/end
    points = result[:routes][0][:activities].collect{ |a| a[:point_id] }
    size.times.each{ |i|
      assert_includes points, "point_#{i}", "Point missing: #{i}"
    }
  end
end