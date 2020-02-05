#' A nice projection for the Four Corners states
#'
#' In PROJ.4:
#' "+proj=lcc +lat_1=41.0034439990657 +lat_2=32.9892379991201 +lat_0=37.0002329990929
#' +lon_0=-109.050431 +x_0=-109.050431 +x_y=-109.050431"
#'
#' @format A character string with the PROJ.4 projection information
"four_corners_lcc_proj"

#' The boundaries of the Four Corners states
#'
#' These data are derived from the US Census TIGRIS database.
#'
#' @format Simple feature collection with 4 features and 2 fields:
#' \describe{
#'   \item{STATEFP}{the state's FIPS code}
#'   \item{geometry}{the state's boundary}
#'  }
"four_corners_states"

#' The boundaries of the Upland US Southwest
#'
#' The UUSW was geographically defined by Bocinsky et al. 2016 as the region between 105–113ºW and 32–38ºN.
#'
#' @format Geometry set for 1 feature
"uusw_boundary"

#' The boundaries of the Upland US Southwest counties used in Robinson et al. 2020
#'
#' The UUSW was geographically defined by Bocinsky et al. 2016 as the region between 105–113ºW and 32–38ºN.
#' Robinson et al. 2020 refined that definition in two ways.
#' First, because location data for the radiocarbon database are only resolved to the county
#' level for most sites, the authors defined their study region to include all counties whose
#' geographic centroids fall within the region from Bocinsky et al. 2016.
#' Second, because of the generally poor tree-ring date record in the Sonoran Desert,
#' the authors roughly exclude the Phoenix and Tucson basins by dropping
#' Maricopa, Pinal, and Pima counties in Arizona.
#'
#' @format SSimple feature collection with 40 features and 2 field:
#' \describe{
#'   \item{County}{the county's name and state}
#'   \item{geometry}{the county's boundary}
#'  }
"uusw_counties"

#' The boundaries of the Village Ecodynamics Project (VEP) study areas
#'
#' @format Simple feature collection with 2 features and 1 field:
#' \describe{
#'   \item{Study Area}{the VEP study area's name}
#'   \item{geometry}{the VEP study area's boundary}
#'  }
"vep_study_areas"

#' The Village Ecodynamics Project (VEP) demographic reconstructions
#'
#' @format A data frame with 32 rows and 5 variables:
#' \describe{
#'   \item{Study Area}{the VEP study area}
#'   \item{Period}{the VEP modeling period}
#'   \item{Start}{the VEP modeling period starting year (AD)}
#'   \item{End}{the VEP modeling period ending year (AD)}
#'   \item{Population}{the VEP population estimate, in persons}
#'  }
"vep_demography"

#' A hillshade of the Four Corners states
#'
#' This hillshade is at 500m resolution, and in the four_corners_lcc_proj projection.
#' These data are appropriate for plotting with ggplot2.
#'
#' @format A data frame with 5,556,936 rows and 3 variables:
#' \describe{
#'   \item{x}{the easting of the hillshade value}
#'   \item{y}{the northing of the hillshade value}
#'   \item{ID}{the hillshade value}
#'  }
"swus_hillshade_500m"
