import 'dart:math';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// GPS飘点过滤器
/// 用于在轨迹绘制前过滤掉异常的GPS漂移点，不影响上报逻辑
///
/// 覆盖三类场景：
/// 1. 大飘点：GPS突然跳到几公里外又回来（基站切换等）
/// 2. 小范围抖动：用户静止时GPS在附近几百米内来回漂移
/// 3. 信号差漂移：室内/隧道等弱信号场景的中等范围漂移
class TrackPointFilter {
  /// 最大合理速度 (m/s)，超过此速度认为可能是飘点
  /// 500 km/h ≈ 138.9 m/s，覆盖高铁场景
  static const double _maxReasonableSpeed = 139.0;

  /// 纯距离飘点判定阈值 (米)
  /// 当没有时间信息时，单次跳跃超过此距离视为可疑
  static const double _distanceJumpThreshold = 5000.0;

  /// 尖刺检测比例阈值
  /// 当 distance(prev, next) < distance(prev, current) * 此比例 时，
  /// 认为 current 是一个尖刺飘点（跳远又跳回）
  static const double _spikeRatio = 0.4;

  /// 小范围抖动的距离上限 (米)
  /// 静止时GPS通常在此范围内漂移（室内可达500m+）
  static const double _jitterDistanceMax = 1000.0;

  /// 小范围抖动的尖刺比例（比大飘点更宽松，因为小范围更常见）
  static const double _jitterSpikeRatio = 0.65;

  /// 静止聚类半径 (米)
  /// 连续点都在此范围内视为用户静止，压缩为少量代表点
  static const double _stationaryClusterRadius = 100.0;

  /// 聚类压缩的最小点数
  /// 至少这么多连续点在聚类半径内才触发压缩
  static const int _minClusterSize = 4;

  /// 最少点数要求，少于此数量不做过滤
  static const int _minPointsForFilter = 3;

  /// 对 TrackLocation 列表进行飘点过滤
  /// 两阶段处理：
  /// 1. 逐点尖刺/抖动过滤（去除飘点和抖动点）
  /// 2. 静止聚类压缩（合并静止时段的冗余点）
  static List<TrackLocation> filterLocations(List<TrackLocation> locations) {
    if (locations.length < _minPointsForFilter) {
      return locations;
    }

    final totalCount = locations.length;

    // === 第一阶段：逐点飘点/抖动过滤 ===
    final spikeFiltered = _filterSpikesAndJitter(locations);
    final spikeRemoved = totalCount - spikeFiltered.length;

    // === 第二阶段：静止聚类压缩 ===
    final clusterCompressed = _compressStationaryClusters(spikeFiltered);
    final clusterRemoved = spikeFiltered.length - clusterCompressed.length;

    final totalRemoved = spikeRemoved + clusterRemoved;
    if (totalRemoved > 0) {
      logWarning('📍 [飘点过滤] 原始: $totalCount, '
          '飘点移除: $spikeRemoved, 静止压缩: $clusterRemoved, '
          '最终: ${clusterCompressed.length}');
    }

    return clusterCompressed;
  }

  /// 第一阶段：逐点尖刺和抖动过滤
  static List<TrackLocation> _filterSpikesAndJitter(List<TrackLocation> locations) {
    final filtered = <TrackLocation>[];
    final totalCount = locations.length;

    // 第一个点始终保留
    filtered.add(locations.first);

    for (int i = 1; i < totalCount - 1; i++) {
      final prev = filtered.last; // 使用已过滤列表的最后一个点作为前驱
      final current = locations[i];
      final next = locations[i + 1];

      if (_isDriftPoint(prev, current, next)) {
        continue;
      }

      filtered.add(current);
    }

    // 最后一个点：检查它是否相对于过滤后的最后一个点也是飘点
    if (totalCount >= 2) {
      final lastPoint = locations.last;
      if (filtered.length >= 2) {
        final lastFiltered = filtered.last;
        final distToLast = _haversineDistance(
          lastFiltered.lat, lastFiltered.lng,
          lastPoint.lat, lastPoint.lng,
        );
        // 最后一个点跳跃超过抖动范围，且回到前一个点附近 → 飘点
        if (distToLast > _jitterDistanceMax) {
          final prevFiltered = filtered[filtered.length - 2];
          final distPrevToLast = _haversineDistance(
            prevFiltered.lat, prevFiltered.lng,
            lastFiltered.lat, lastFiltered.lng,
          );
          if (distPrevToLast < 100) {
            // 飘点，不添加
          } else {
            filtered.add(lastPoint);
          }
        } else {
          filtered.add(lastPoint);
        }
      } else {
        filtered.add(lastPoint);
      }
    }

    return filtered;
  }

  /// 第二阶段：静止聚类压缩
  /// 当连续多个点都聚集在一个小范围内（用户静止），压缩为首尾两个点
  /// 避免静止时轨迹在原地画出密集的锯齿线
  static List<TrackLocation> _compressStationaryClusters(List<TrackLocation> locations) {
    if (locations.length < _minClusterSize) return locations;

    final result = <TrackLocation>[];
    int i = 0;

    while (i < locations.length) {
      final anchor = locations[i];
      result.add(anchor);

      // 从当前点开始，找出所有在聚类半径内的连续点   
      int clusterEnd = i;
      for (int j = i + 1; j < locations.length; j++) {
        final dist = _haversineDistance(
          anchor.lat, anchor.lng,
          locations[j].lat, locations[j].lng,
        );
        if (dist <= _stationaryClusterRadius) {
          clusterEnd = j;
        } else {
          break;
        }
      }

      final clusterSize = clusterEnd - i + 1;
      if (clusterSize >= _minClusterSize) {
        // 找到静止聚类，跳过中间点，只保留最后一个点
        // （第一个点 anchor 已添加）
        if (clusterEnd > i) {
          result.add(locations[clusterEnd]);
        }
        i = clusterEnd + 1;
      } else {
        // 不构成聚类，正常前进
        i++;
      }
    }

    return result;
  }

  /// 判断 current 是否为飘点
  /// 综合使用速度检测和尖刺模式检测
  static bool _isDriftPoint(
    TrackLocation prev,
    TrackLocation current,
    TrackLocation next,
  ) {
    final distPrevToCurr = _haversineDistance(
      prev.lat, prev.lng, current.lat, current.lng,
    );
    final distCurrToNext = _haversineDistance(
      current.lat, current.lng, next.lat, next.lng,
    );
    final distPrevToNext = _haversineDistance(
      prev.lat, prev.lng, next.lat, next.lng,
    );

    // === 策略1：基于时间的速度检测 ===
    final timePrev = _parseTime(prev.time);
    final timeCurr = _parseTime(current.time);
    final timeNext = _parseTime(next.time);

    if (timePrev != null && timeCurr != null) {
      final timeDiffSeconds = (timeCurr - timePrev).abs();
      if (timeDiffSeconds > 0) {
        final speed = distPrevToCurr / timeDiffSeconds;
        if (speed > _maxReasonableSpeed) {
          // 速度异常，再检查尖刺模式确认是飘点而非真实高速移动
          // 如果跳过此点后前后两点距离合理，则确认是飘点
          if (distPrevToNext < distPrevToCurr * _spikeRatio) {
            return true;
          }
          // 如果后续点也很远，可能是真实移动（如坐飞机），检查回跳模式
          if (timeNext != null) {
            final timeDiffNext = (timeNext - timeCurr).abs();
            if (timeDiffNext > 0) {
              final speedNext = distCurrToNext / timeDiffNext;
              // 来回都是超高速 = 飘点来回跳
              if (speedNext > _maxReasonableSpeed && distPrevToNext < distPrevToCurr * 0.6) {
                return true;
              }
            }
          }
        }
      }
    }

    // === 策略2：纯距离尖刺检测（时间不可用或作为补充） ===
    // 经典飘点模式：current远离prev和next，但prev和next很近
    if (distPrevToCurr > _distanceJumpThreshold && distCurrToNext > _distanceJumpThreshold) {
      // 两侧都跳跃很远，且跳过此点后距离很近 → 典型飘点
      if (distPrevToNext < distPrevToCurr * _spikeRatio) {
        return true;
      }
    }

    // === 策略3：单侧大跳跃 + 回跳模式 ===
    // prev → current 跳跃很远，但 prev → next 很近（说明next回到了prev附近）
    if (distPrevToCurr > _distanceJumpThreshold) {
      if (distPrevToNext < distPrevToCurr * _spikeRatio) {
        return true;
      }
    }

    // === 策略4：小范围抖动检测（用户静止时GPS在附近几百米内来回漂移） ===
    // 距离在20m~1000m范围内，且呈现尖刺模式（跳出去又跳回来）
    if (distPrevToCurr > 20 && distPrevToCurr < _jitterDistanceMax) {
      if (distPrevToNext < distPrevToCurr * _jitterSpikeRatio) {
        // 有时间数据时：短时间间隔内的来回跳跃 → 静态抖动
        if (timePrev != null && timeCurr != null) {
          final timeDiff = (timeCurr - timePrev).abs();
          // 3分钟内的短间隔跳跃并回弹
          if (timeDiff > 0 && timeDiff <= 180) {
            return true;
          }
        } else {
          // 无时间数据：仅靠距离比例判断，要求更严格的比例
          if (distPrevToNext < distPrevToCurr * _spikeRatio) {
            return true;
          }
        }
      }
    }

    // === 策略5：信号差区域的方向突变检测 ===
    // 在较短时间内出现「去→回」模式：prev→curr方向与curr→next方向几乎相反
    // 且跳过此点后路径明显更短
    if (timePrev != null && timeCurr != null && timeNext != null) {
      final timeDiff1 = (timeCurr - timePrev).abs();
      final timeDiff2 = (timeNext - timeCurr).abs();
      if (timeDiff1 > 0 && timeDiff2 > 0 && timeDiff1 <= 300 && timeDiff2 <= 300) {
        final totalDetour = distPrevToCurr + distCurrToNext;
        // 绕路比：跳过该点的直线距离 vs 经过该点的折线距离
        // 比值越小说明该点越是「绕远路」的异常点
        if (totalDetour > 100 && distPrevToNext < totalDetour * 0.3) {
          return true;
        }
      }
    }

    return false;
  }

  /// 解析时间字符串为秒级时间戳
  /// 支持多种格式：纯数字时间戳、ISO 8601、常见日期时间格式
  static int? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;

    // 尝试解析为纯数字时间戳
    final numericValue = int.tryParse(timeStr);
    if (numericValue != null) {
      // 判断是秒级还是毫秒级时间戳
      if (numericValue > 1000000000000) {
        // 毫秒级，转换为秒级
        return numericValue ~/ 1000;
      } else if (numericValue > 1000000000) {
        // 秒级时间戳
        return numericValue;
      }
    }

    // 尝试解析为日期时间字符串
    try {
      final dateTime = DateTime.tryParse(timeStr);
      if (dateTime != null) {
        return dateTime.millisecondsSinceEpoch ~/ 1000;
      }
    } catch (_) {}

    return null;
  }

  /// Haversine公式计算两个经纬度点之间的距离（米）
  static double _haversineDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const double earthRadius = 6371000; // 地球半径，米
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
  

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
  
}
