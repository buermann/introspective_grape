
0.1.8 9/10/2016
==============

### Features

Add date range filters for the index page.

0.1.6 9/10/2016
==============

### Bug Fix

The before hook snake casing parameters in the API was preventing the assignment of default values, this was moved to an after_validation hook.

### Features

Grape::Kaminari pagination was added to the index actions if configured in the parent class.

0.1.5 6/26/2016
==============

### Bug Fix

Reload the model from the database before presenting it to the user after create/update, as
some deeply nested association changes will not be properly loaded by active record.

0.1.4 5/11/2016
==============

### Features

Added an include_actions declaration as the inverse of exclude_actions.

0.1.1 5/11/2016
==============

### Features

Stop monkey patching Grape's json formatter and instead use Grape's "formatter" 
with our own CamelJson module.

0.1.0 5/8/2016
==============

### Features

Add simple filter for index endpoints.

### Fixes

Refactor API generation to reduce the code complexity.
