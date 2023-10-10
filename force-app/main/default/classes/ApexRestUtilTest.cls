@isTest
class ApexRestUtilTest {
  static String[] input = new List<String>{
    '{' +
    '  "attributes" : {' +
    '    "type" : "Account",' +
    '    "url" : "/services/data/v58.0/sobjects/Account/0015500001c38b7AAA"' +
    '  },' +
    '  "Id" : "0015500001c38b7AAA",' +
    '  "Name" : "Test STore 11",' +
    '  "ParentId" : "0015500001c38b2AAA",' +
    '  "Restaurant_ID__c" : "987611",' +
    '  "Alcohol_Addendum_Signed__c" : false,' +
    '  "Alcohol_Eligibility__c" : "Not Eligible",' +
    '  "Parent" : {' +
    '    "attributes" : {' +
    '      "type" : "Account",' +
    '      "url" : "/services/data/v58.0/sobjects/Account/0015500001c38b2AAA"' +
    '    },' +
    '    "Id" : "0015500001c38b2AAA",' +
    '    "Name" : "Test Parent 1",' +
    '    "Alcohol_Addendum_Signed__c" : false,' +
    '    "Alcohol_Eligibility__c" : "Not Eligible",' +
    '    "ParentId" : "0015500001c5Pk5AAE",' +
    '    "Parent" : {' +
    '      "attributes" : {' +
    '        "type" : "Account",' +
    '        "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '      },' +
    '      "Id" : "0015500001c5Pk5AAE",' +
    '      "Name" : "Grand Parent",' +
    '      "Alcohol_Addendum_Signed__c" : false,' +
    '      "Alcohol_Eligibility__c" : "Not Eligible"' +
    '    }' +
    '  }' +
    '}',
    '{' +
    '  "attributes" : {' +
    '    "type" : "Account",' +
    '    "url" : "/services/data/v58.0/sobjects/Account/0015500001c5PkPAAU"' +
    '  },' +
    '  "Id" : "0015500001c5PkPAAU",' +
    '  "Name" : "Test STore 21",' +
    '  "ParentId" : "0015500001c5Pk0AAE",' +
    '  "Restaurant_ID__c" : "987621",' +
    '  "Alcohol_Addendum_Signed__c" : false,' +
    '  "Alcohol_Eligibility__c" : "Not Eligible",' +
    '  "Parent" : {' +
    '    "attributes" : {' +
    '      "type" : "Account",' +
    '      "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk0AAE"' +
    '    },' +
    '    "Id" : "0015500001c5Pk0AAE",' +
    '    "Name" : "The f* parent 2",' +
    '    "Alcohol_Addendum_Signed__c" : false,' +
    '    "Alcohol_Eligibility__c" : "Not Eligible",' +
    '    "ParentId" : "0015500001c5Pk5AAE",' +
    '    "Parent" : {' +
    '      "attributes" : {' +
    '        "type" : "Account",' +
    '        "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '      },' +
    '      "Id" : "0015500001c5Pk5AAE",' +
    '      "Name" : "Grand Parent",' +
    '      "Alcohol_Addendum_Signed__c" : false,' +
    '      "Alcohol_Eligibility__c" : "Not Eligible"' +
    '    }' +
    '  }' +
    '}',
    '{' +
    '  "attributes" : {' +
    '    "type" : "Account",' +
    '    "url" : "/services/data/v58.0/sobjects/Account/0015500001c5PkjAAE"' +
    '  },' +
    '  "Id" : "0015500001c5PkjAAE",' +
    '  "Name" : "Test STore 22",' +
    '  "ParentId" : "0015500001c5Pk0AAE",' +
    '  "Restaurant_ID__c" : "987622",' +
    '  "Alcohol_Addendum_Signed__c" : false,' +
    '  "Alcohol_Eligibility__c" : "Not Eligible",' +
    '  "Parent" : {' +
    '    "attributes" : {' +
    '      "type" : "Account",' +
    '      "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk0AAE"' +
    '    },' +
    '    "Id" : "0015500001c5Pk0AAE",' +
    '    "Name" : "The f* parent 2",' +
    '    "Alcohol_Addendum_Signed__c" : false,' +
    '    "Alcohol_Eligibility__c" : "Not Eligible",' +
    '    "ParentId" : "0015500001c5Pk5AAE",' +
    '    "Parent" : {' +
    '      "attributes" : {' +
    '        "type" : "Account",' +
    '        "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '      },' +
    '      "Id" : "0015500001c5Pk5AAE",' +
    '      "Name" : "Grand Parent",' +
    '      "Alcohol_Addendum_Signed__c" : false,' +
    '      "Alcohol_Eligibility__c" : "Not Eligible"' +
    '    }' +
    '  }' +
    '}',
    '{' +
    '  "attributes" : {' +
    '    "type" : "Account",' +
    '    "url" : "/services/data/v58.0/sobjects/Account/0015500001c5PgXAAU"' +
    '  },' +
    '  "Id" : "0015500001c5PgXAAU",' +
    '  "Name" : "Test STore 12",' +
    '  "ParentId" : "0015500001c38b2AAA",' +
    '  "Restaurant_ID__c" : "987612",' +
    '  "Alcohol_Addendum_Signed__c" : false,' +
    '  "Alcohol_Eligibility__c" : "Not Eligible",' +
    '  "Parent" : {' +
    '    "attributes" : {' +
    '      "type" : "Account",' +
    '      "url" : "/services/data/v58.0/sobjects/Account/0015500001c38b2AAA"' +
    '    },' +
    '    "Id" : "0015500001c38b2AAA",' +
    '    "Name" : "Test Parent 1",' +
    '    "Alcohol_Addendum_Signed__c" : false,' +
    '    "Alcohol_Eligibility__c" : "Not Eligible",' +
    '    "ParentId" : "0015500001c5Pk5AAE",' +
    '    "Parent" : {' +
    '      "attributes" : {' +
    '        "type" : "Account",' +
    '        "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '      },' +
    '      "Id" : "0015500001c5Pk5AAE",' +
    '      "Name" : "Grand Parent",' +
    '      "Alcohol_Addendum_Signed__c" : false,' +
    '      "Alcohol_Eligibility__c" : "Not Eligible"' +
    '    }' +
    '  }' +
    '}',
    '{' +
    '  "attributes" : {' +
    '    "type" : "Account",' +
    '    "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '  },' +
    '  "Id" : "0015500001c5Pk5AAE",' +
    '  "Name" : "Grand Parent",' +
    '  "Alcohol_Addendum_Signed__c" : false,' +
    '  "Alcohol_Eligibility__c" : "Not Eligible",' +
    '  "ChildAccounts" : {' +
    '    "totalSize" : 2,' +
    '    "done" : true,' +
    '    "records" : [ {' +
    '      "attributes" : {' +
    '        "type" : "Account",' +
    '        "url" : "/services/data/v58.0/sobjects/Account/0015500001c38b2AAA"' +
    '      },' +
    '      "ParentId" : "0015500001c5Pk5AAE",' +
    '      "Id" : "0015500001c38b2AAA",' +
    '      "Name" : "Test Parent 1",' +
    '      "Alcohol_Addendum_Signed__c" : false,' +
    '      "Alcohol_Eligibility__c" : "Not Eligible",' +
    '      "Parent" : {' +
    '        "attributes" : {' +
    '          "type" : "Account",' +
    '          "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '        },' +
    '        "Id" : "0015500001c5Pk5AAE",' +
    '        "Name" : "Grand Parent",' +
    '        "Alcohol_Addendum_Signed__c" : false,' +
    '        "Alcohol_Eligibility__c" : "Not Eligible"' +
    '      }' +
    '    }, {' +
    '      "attributes" : {' +
    '        "type" : "Account",' +
    '        "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk0AAE"' +
    '      },' +
    '      "ParentId" : "0015500001c5Pk5AAE",' +
    '      "Id" : "0015500001c5Pk0AAE",' +
    '      "Name" : "The f* parent 2",' +
    '      "Alcohol_Addendum_Signed__c" : false,' +
    '      "Alcohol_Eligibility__c" : "Not Eligible",' +
    '      "Parent" : {' +
    '        "attributes" : {' +
    '          "type" : "Account",' +
    '          "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '        },' +
    '        "Id" : "0015500001c5Pk5AAE",' +
    '        "Name" : "Grand Parent",' +
    '        "Alcohol_Addendum_Signed__c" : false,' +
    '        "Alcohol_Eligibility__c" : "Not Eligible"' +
    '      }' +
    '    } ]' +
    '  }' +
    '}',
    '{' +
    '  "attributes" : {' +
    '    "type" : "Account",' +
    '    "url" : "/services/data/v58.0/sobjects/Account/0015500001c38b2AAA"' +
    '  },' +
    '  "Id" : "0015500001c38b2AAA",' +
    '  "Name" : "Test Parent 1",' +
    '  "ParentId" : "0015500001c5Pk5AAE",' +
    '  "Alcohol_Addendum_Signed__c" : false,' +
    '  "Alcohol_Eligibility__c" : "Not Eligible",' +
    '  "ChildAccounts" : {' +
    '    "totalSize" : 2,' +
    '    "done" : true,' +
    '    "records" : [ {' +
    '      "attributes" : {' +
    '        "type" : "Account",' +
    '        "url" : "/services/data/v58.0/sobjects/Account/0015500001c38b7AAA"' +
    '      },' +
    '      "ParentId" : "0015500001c38b2AAA",' +
    '      "Id" : "0015500001c38b7AAA",' +
    '      "Name" : "Test STore 11",' +
    '      "Restaurant_ID__c" : "987611",' +
    '      "Alcohol_Addendum_Signed__c" : false,' +
    '      "Alcohol_Eligibility__c" : "Not Eligible",' +
    '      "Parent" : {' +
    '        "attributes" : {' +
    '          "type" : "Account",' +
    '          "url" : "/services/data/v58.0/sobjects/Account/0015500001c38b2AAA"' +
    '        },' +
    '        "Id" : "0015500001c38b2AAA",' +
    '        "Name" : "Test Parent 1",' +
    '        "Alcohol_Addendum_Signed__c" : false,' +
    '        "Alcohol_Eligibility__c" : "Not Eligible",' +
    '        "ParentId" : "0015500001c5Pk5AAE",' +
    '        "Parent" : {' +
    '          "attributes" : {' +
    '            "type" : "Account",' +
    '            "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '          },' +
    '          "Id" : "0015500001c5Pk5AAE",' +
    '          "Name" : "Grand Parent",' +
    '          "Alcohol_Addendum_Signed__c" : false,' +
    '          "Alcohol_Eligibility__c" : "Not Eligible"' +
    '        }' +
    '      }' +
    '    }, {' +
    '      "attributes" : {' +
    '        "type" : "Account",' +
    '        "url" : "/services/data/v58.0/sobjects/Account/0015500001c5PgXAAU"' +
    '      },' +
    '      "ParentId" : "0015500001c38b2AAA",' +
    '      "Id" : "0015500001c5PgXAAU",' +
    '      "Name" : "Test STore 12",' +
    '      "Restaurant_ID__c" : "987612",' +
    '      "Alcohol_Addendum_Signed__c" : false,' +
    '      "Alcohol_Eligibility__c" : "Not Eligible",' +
    '      "Parent" : {' +
    '        "attributes" : {' +
    '          "type" : "Account",' +
    '          "url" : "/services/data/v58.0/sobjects/Account/0015500001c38b2AAA"' +
    '        },' +
    '        "Id" : "0015500001c38b2AAA",' +
    '        "Name" : "Test Parent 1",' +
    '        "Alcohol_Addendum_Signed__c" : false,' +
    '        "Alcohol_Eligibility__c" : "Not Eligible",' +
    '        "ParentId" : "0015500001c5Pk5AAE",' +
    '        "Parent" : {' +
    '          "attributes" : {' +
    '            "type" : "Account",' +
    '            "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '          },' +
    '          "Id" : "0015500001c5Pk5AAE",' +
    '          "Name" : "Grand Parent",' +
    '          "Alcohol_Addendum_Signed__c" : false,' +
    '          "Alcohol_Eligibility__c" : "Not Eligible"' +
    '        }' +
    '      }' +
    '    } ]' +
    '  },' +
    '  "Parent" : {' +
    '    "attributes" : {' +
    '      "type" : "Account",' +
    '      "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '    },' +
    '    "Id" : "0015500001c5Pk5AAE",' +
    '    "Name" : "Grand Parent",' +
    '    "Alcohol_Addendum_Signed__c" : false,' +
    '    "Alcohol_Eligibility__c" : "Not Eligible"' +
    '  }' +
    '}',
    '{' +
    '  "attributes" : {' +
    '    "type" : "Account",' +
    '    "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk0AAE"' +
    '  },' +
    '  "Id" : "0015500001c5Pk0AAE",' +
    '  "Name" : "The f* parent 2",' +
    '  "ParentId" : "0015500001c5Pk5AAE",' +
    '  "Alcohol_Addendum_Signed__c" : false,' +
    '  "Alcohol_Eligibility__c" : "Not Eligible",' +
    '  "ChildAccounts" : {' +
    '    "totalSize" : 2,' +
    '    "done" : true,' +
    '    "records" : [ {' +
    '      "attributes" : {' +
    '        "type" : "Account",' +
    '        "url" : "/services/data/v58.0/sobjects/Account/0015500001c5PkPAAU"' +
    '      },' +
    '      "ParentId" : "0015500001c5Pk0AAE",' +
    '      "Id" : "0015500001c5PkPAAU",' +
    '      "Name" : "Test STore 21",' +
    '      "Restaurant_ID__c" : "987621",' +
    '      "Alcohol_Addendum_Signed__c" : false,' +
    '      "Alcohol_Eligibility__c" : "Not Eligible",' +
    '      "Parent" : {' +
    '        "attributes" : {' +
    '          "type" : "Account",' +
    '          "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk0AAE"' +
    '        },' +
    '        "Id" : "0015500001c5Pk0AAE",' +
    '        "Name" : "The f* parent 2",' +
    '        "Alcohol_Addendum_Signed__c" : false,' +
    '        "Alcohol_Eligibility__c" : "Not Eligible",' +
    '        "ParentId" : "0015500001c5Pk5AAE",' +
    '        "Parent" : {' +
    '          "attributes" : {' +
    '            "type" : "Account",' +
    '            "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '          },' +
    '          "Id" : "0015500001c5Pk5AAE",' +
    '          "Name" : "Grand Parent",' +
    '          "Alcohol_Addendum_Signed__c" : false,' +
    '          "Alcohol_Eligibility__c" : "Not Eligible"' +
    '        }' +
    '      }' +
    '    }, {' +
    '      "attributes" : {' +
    '        "type" : "Account",' +
    '        "url" : "/services/data/v58.0/sobjects/Account/0015500001c5PkjAAE"' +
    '      },' +
    '      "ParentId" : "0015500001c5Pk0AAE",' +
    '      "Id" : "0015500001c5PkjAAE",' +
    '      "Name" : "Test STore 22",' +
    '      "Restaurant_ID__c" : "987622",' +
    '      "Alcohol_Addendum_Signed__c" : false,' +
    '      "Alcohol_Eligibility__c" : "Not Eligible",' +
    '      "Parent" : {' +
    '        "attributes" : {' +
    '          "type" : "Account",' +
    '          "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk0AAE"' +
    '        },' +
    '        "Id" : "0015500001c5Pk0AAE",' +
    '        "Name" : "The f* parent 2",' +
    '        "Alcohol_Addendum_Signed__c" : false,' +
    '        "Alcohol_Eligibility__c" : "Not Eligible",' +
    '        "ParentId" : "0015500001c5Pk5AAE",' +
    '        "Parent" : {' +
    '          "attributes" : {' +
    '            "type" : "Account",' +
    '            "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '          },' +
    '          "Id" : "0015500001c5Pk5AAE",' +
    '          "Name" : "Grand Parent",' +
    '          "Alcohol_Addendum_Signed__c" : false,' +
    '          "Alcohol_Eligibility__c" : "Not Eligible"' +
    '        }' +
    '      }' +
    '    } ]' +
    '  },' +
    '  "Parent" : {' +
    '    "attributes" : {' +
    '      "type" : "Account",' +
    '      "url" : "/services/data/v58.0/sobjects/Account/0015500001c5Pk5AAE"' +
    '    },' +
    '    "Id" : "0015500001c5Pk5AAE",' +
    '    "Name" : "Grand Parent",' +
    '    "Alcohol_Addendum_Signed__c" : false,' +
    '    "Alcohol_Eligibility__c" : "Not Eligible"' +
    '  }' +
    '}'
  };

  static String output = '[{"Account.Parent.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.Parent.Parent.Name":"Grand Parent","Account.Parent.Parent.Id":"0015500001c5Pk5AAE","Account.Parent.Parent.Alcohol_Addendum_Signed__c":false,"Account.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.Parent.Name":"Test Parent 1","Account.Parent.Id":"0015500001c38b2AAA","Account.Parent.Alcohol_Addendum_Signed__c":false,"Account.Parent.ParentId":"0015500001c5Pk5AAE","Account.Alcohol_Eligibility__c":"Not Eligible","Account.Name":"Test STore 11","Account.Id":"0015500001c38b7AAA","Account.Alcohol_Addendum_Signed__c":false,"Account.Restaurant_ID__c":"987611","Account.ParentId":"0015500001c38b2AAA"},{"Account.Parent.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.Parent.Parent.Name":"Grand Parent","Account.Parent.Parent.Id":"0015500001c5Pk5AAE","Account.Parent.Parent.Alcohol_Addendum_Signed__c":false,"Account.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.Parent.Name":"The f* parent 2","Account.Parent.Id":"0015500001c5Pk0AAE","Account.Parent.Alcohol_Addendum_Signed__c":false,"Account.Parent.ParentId":"0015500001c5Pk5AAE","Account.Alcohol_Eligibility__c":"Not Eligible","Account.Name":"Test STore 21","Account.Id":"0015500001c5PkPAAU","Account.Alcohol_Addendum_Signed__c":false,"Account.Restaurant_ID__c":"987621","Account.ParentId":"0015500001c5Pk0AAE"},{"Account.Parent.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.Parent.Parent.Name":"Grand Parent","Account.Parent.Parent.Id":"0015500001c5Pk5AAE","Account.Parent.Parent.Alcohol_Addendum_Signed__c":false,"Account.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.Parent.Name":"The f* parent 2","Account.Parent.Id":"0015500001c5Pk0AAE","Account.Parent.Alcohol_Addendum_Signed__c":false,"Account.Parent.ParentId":"0015500001c5Pk5AAE","Account.Alcohol_Eligibility__c":"Not Eligible","Account.Name":"Test STore 22","Account.Id":"0015500001c5PkjAAE","Account.Alcohol_Addendum_Signed__c":false,"Account.Restaurant_ID__c":"987622","Account.ParentId":"0015500001c5Pk0AAE"},{"Account.Parent.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.Parent.Parent.Name":"Grand Parent","Account.Parent.Parent.Id":"0015500001c5Pk5AAE","Account.Parent.Parent.Alcohol_Addendum_Signed__c":false,"Account.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.Parent.Name":"Test Parent 1","Account.Parent.Id":"0015500001c38b2AAA","Account.Parent.Alcohol_Addendum_Signed__c":false,"Account.Parent.ParentId":"0015500001c5Pk5AAE","Account.Alcohol_Eligibility__c":"Not Eligible","Account.Name":"Test STore 12","Account.Id":"0015500001c5PgXAAU","Account.Alcohol_Addendum_Signed__c":false,"Account.Restaurant_ID__c":"987612","Account.ParentId":"0015500001c38b2AAA"},{"Account.ChildAccounts":[{"Account.ChildAccounts.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Parent.Name":"Grand Parent","Account.ChildAccounts.Parent.Id":"0015500001c5Pk5AAE","Account.ChildAccounts.Parent.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Name":"Test Parent 1","Account.ChildAccounts.Id":"0015500001c38b2AAA","Account.ChildAccounts.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.ParentId":"0015500001c5Pk5AAE"},{"Account.ChildAccounts.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Parent.Name":"Grand Parent","Account.ChildAccounts.Parent.Id":"0015500001c5Pk5AAE","Account.ChildAccounts.Parent.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Name":"The f* parent 2","Account.ChildAccounts.Id":"0015500001c5Pk0AAE","Account.ChildAccounts.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.ParentId":"0015500001c5Pk5AAE"}],"Account.Alcohol_Eligibility__c":"Not Eligible","Account.Name":"Grand Parent","Account.Id":"0015500001c5Pk5AAE","Account.Alcohol_Addendum_Signed__c":false},{"Account.ChildAccounts":[{"Account.ChildAccounts.Parent.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Parent.Parent.Name":"Grand Parent","Account.ChildAccounts.Parent.Parent.Id":"0015500001c5Pk5AAE","Account.ChildAccounts.Parent.Parent.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Parent.Name":"Test Parent 1","Account.ChildAccounts.Parent.Id":"0015500001c38b2AAA","Account.ChildAccounts.Parent.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Parent.ParentId":"0015500001c5Pk5AAE","Account.ChildAccounts.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Name":"Test STore 11","Account.ChildAccounts.Id":"0015500001c38b7AAA","Account.ChildAccounts.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Restaurant_ID__c":"987611","Account.ChildAccounts.ParentId":"0015500001c38b2AAA"},{"Account.ChildAccounts.Parent.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Parent.Parent.Name":"Grand Parent","Account.ChildAccounts.Parent.Parent.Id":"0015500001c5Pk5AAE","Account.ChildAccounts.Parent.Parent.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Parent.Name":"Test Parent 1","Account.ChildAccounts.Parent.Id":"0015500001c38b2AAA","Account.ChildAccounts.Parent.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Parent.ParentId":"0015500001c5Pk5AAE","Account.ChildAccounts.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Name":"Test STore 12","Account.ChildAccounts.Id":"0015500001c5PgXAAU","Account.ChildAccounts.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Restaurant_ID__c":"987612","Account.ChildAccounts.ParentId":"0015500001c38b2AAA"}],"Account.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.Parent.Name":"Grand Parent","Account.Parent.Id":"0015500001c5Pk5AAE","Account.Parent.Alcohol_Addendum_Signed__c":false,"Account.Alcohol_Eligibility__c":"Not Eligible","Account.Name":"Test Parent 1","Account.Id":"0015500001c38b2AAA","Account.Alcohol_Addendum_Signed__c":false,"Account.ParentId":"0015500001c5Pk5AAE"},{"Account.ChildAccounts":[{"Account.ChildAccounts.Parent.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Parent.Parent.Name":"Grand Parent","Account.ChildAccounts.Parent.Parent.Id":"0015500001c5Pk5AAE","Account.ChildAccounts.Parent.Parent.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Parent.Name":"The f* parent 2","Account.ChildAccounts.Parent.Id":"0015500001c5Pk0AAE","Account.ChildAccounts.Parent.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Parent.ParentId":"0015500001c5Pk5AAE","Account.ChildAccounts.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Name":"Test STore 21","Account.ChildAccounts.Id":"0015500001c5PkPAAU","Account.ChildAccounts.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Restaurant_ID__c":"987621","Account.ChildAccounts.ParentId":"0015500001c5Pk0AAE"},{"Account.ChildAccounts.Parent.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Parent.Parent.Name":"Grand Parent","Account.ChildAccounts.Parent.Parent.Id":"0015500001c5Pk5AAE","Account.ChildAccounts.Parent.Parent.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Parent.Name":"The f* parent 2","Account.ChildAccounts.Parent.Id":"0015500001c5Pk0AAE","Account.ChildAccounts.Parent.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Parent.ParentId":"0015500001c5Pk5AAE","Account.ChildAccounts.Alcohol_Eligibility__c":"Not Eligible","Account.ChildAccounts.Name":"Test STore 22","Account.ChildAccounts.Id":"0015500001c5PkjAAE","Account.ChildAccounts.Alcohol_Addendum_Signed__c":false,"Account.ChildAccounts.Restaurant_ID__c":"987622","Account.ChildAccounts.ParentId":"0015500001c5Pk0AAE"}],"Account.Parent.Alcohol_Eligibility__c":"Not Eligible","Account.Parent.Name":"Grand Parent","Account.Parent.Id":"0015500001c5Pk5AAE","Account.Parent.Alcohol_Addendum_Signed__c":false,"Account.Alcohol_Eligibility__c":"Not Eligible","Account.Name":"The f* parent 2","Account.Id":"0015500001c5Pk0AAE","Account.Alcohol_Addendum_Signed__c":false,"Account.ParentId":"0015500001c5Pk5AAE"}]';

  @isTest
  static void testWhenSObjectRecordThenReformatedAsMap() {
    List<Map<String, Object>> reformatedSObjects = new List<Map<String, Object>>{
      ApexRestUtil.reformatSObjectRecord(
        (SObject) JSON.deserialize(input[0], Account.class)
      ),
      ApexRestUtil.reformatSObjectRecord(
        (SObject) JSON.deserialize(input[1], Account.class)
      ),
      ApexRestUtil.reformatSObjectRecord(
        (SObject) JSON.deserialize(input[2], Account.class)
      ),
      ApexRestUtil.reformatSObjectRecord(
        (SObject) JSON.deserialize(input[3], Account.class)
      ),
      ApexRestUtil.reformatSObjectRecord(
        (SObject) JSON.deserialize(input[4], Account.class)
      ),
      ApexRestUtil.reformatSObjectRecord(
        (SObject) JSON.deserialize(input[5], Account.class)
      ),
      ApexRestUtil.reformatSObjectRecord(
        (SObject) JSON.deserialize(input[6], Account.class)
      )
    };
    String assertErrorMessage = 'Expected: \n {0} Actual: \n {1}';
    system.assertEquals(
      output,
      JSON.serialize(reformatedSObjects),
      String.format(
        assertErrorMessage,
        new List<String>{ output, JSON.serialize(reformatedSObjects) }
      )
    );
  }
}