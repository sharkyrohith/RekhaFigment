({
	callout: function(component, name, params, success, failure, abortable) {
		var beginTime, endTime, duration;
		var action = component.get('c.' + name);
		if (params) {
			action.setParams(params);
		}
		if (abortable) {
			action.setAbortable();
		}
		action.setCallback(this, function(response) {
			endTime = Date.now();
			duration = endTime - beginTime;
			console.debug('Callout ' + name + ' completed in ' + duration + 'ms');
			var state = response.getState();
			switch (state) {
				case 'SUCCESS':
				case 'REFRESH':
					var result = response.getReturnValue();
					if (success) {
						success.call(this, result, state);
					}
					break;
				case 'ERROR':
					var errorMessage = 'Unknown error';

					var error = response.getError();
					console.log('Error : ' + JSON.stringify(error));

					if (error && error.length && (error.length > 0) && error[0] && error[0].message) {
						errorMessage = error[0].message;
					}

					if (failure) {
						failure.call(this, { message: errorMessage }, state);
					}
					break;
				case 'INCOMPLETE':
					if (failure) {
						failure.call(this, { message: 'Lost connection to server' }, state);
					}
					break;
				case 'ABORTED':
					if (failure) {
						failure.call(this, { message: 'Operation was aborted' }, state);
					}
					break;
            }
		}, 'ALL');
		beginTime = Date.now();
		$A.enqueueAction(action);
		return action;
	},
})