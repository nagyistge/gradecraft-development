@gradecraft.factory 'PredictorService', ['$http', ($http) ->
    getGradeSchemeElements = ()->
      $http.get("/gse_mass_edit/")

    return {
        getGradeSchemeElements: getGradeSchemeElements
    }
]
