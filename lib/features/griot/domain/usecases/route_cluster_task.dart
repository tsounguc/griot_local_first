import 'package:griot/features/griot/data/gateways/cluster_gateway.dart';

class RouteClusterTask {
  RouteClusterTask(this._clusterGateway);

  final ClusterGateway _clusterGateway;

  Future<String> call({required String task, required String message}) {
    return _clusterGateway.routeTask(task: task, message: message);
  }
}
