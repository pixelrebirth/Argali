angular.module('app', [])
.controller('AdminController', RestController);
function RestController ($scope, $http) {
    $scope.loadJson = function () {
    	var requestContent = "module=" + $scope.module + "&codeset=" + $scope.codeset + "&arg1=" + $scope.arg1
	    $http.post('https://<IP>:<Port>/api', requestContent).
	    // $http.post('/sample.json').
	    success(function(data) {
	        $scope.json = data;
	    }, function(dataError){
	    	$scope.test = dataError
	    });
	}
};