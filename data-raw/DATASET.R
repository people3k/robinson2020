library(magrittr)
library(tidycensus)

## Get the VEP II study area definitions from the `villager` package.
## https://github.com/village-ecodynamics/villager
vepii_cmv_boundary <- villager::vepii_cmv_boundary
vepii_nrg_boundary <- villager::vepii_nrg_boundary

usethis::use_data(vepii_cmv_boundary)
usethis::use_data(vepii_nrg_boundary)

## Create the Upland US Southwest boundary
## The boundary is defined as a geographic rectangle sans Maricopa, Pinal, and Pima counties
uusw_boundary <-
  sf::st_bbox(c(xmin = -113,
                xmax = -105,
                ymin = 32,
                ymax = 38),
              crs = 4326) %>%
  sf::st_as_sfc()

usethis::use_data(uusw_boundary, overwrite = TRUE)

## Create a nice hillshade for the Four Corners states for mapping
# A nice projection for the Four Corners states
four_corners_lcc_proj <- "+proj=lcc +lat_1=37 +lon_0=-109.045225"


# Define the Four Corners states
# "https://prd-tnm.s3.amazonaws.com/StagedProducts/Small-scale/data/Boundaries/statesp010g.gdb_nt00937.tar.gz" %>%
#   download.file(destfile="../Data/data-raw/statesp010g.gdb_nt00937.tar.gz",
#                 mode='wb')
# untar("../Data/data-raw/statesp010g.gdb_nt00937.tar.gz",
#       exdir="../Data/data-raw/statesp010g")
four_corners_states <- "./data-raw/statesp010g/statesp010g.gdb/" %>%
  sf::st_read() %>%
  dplyr::filter(NAME %in%
                  c("Arizona",
                    "Colorado",
                    "New Mexico",
                    "Utah")) %>%
  sf::st_transform(four_corners_lcc_proj) %>%
  sf::st_union()

swus_rast_500 <- raster::raster(raster::extent(-566500,643000,3815000,5052500),
                                nrows = 2475,
                                ncols = 2419,
                                crs = CRS(four_corners_lcc_proj))

swus_ned <- FedData::get_ned(template = four_corners_states %>%
                               sf::st_buffer(20000) %>%
                               as("Spatial"),
                             label = "swus_4C",
                             raw.dir = "./data-raw/ned",
                             extraction.dir = "./data-raw/")

system("gdaldem hillshade ./data-raw/swus_4C_NED_1.tif ./data-derived/swus_4C_hillshade.tif -z 2 -s 111120 -multidirectional -co 'COMPRESS=DEFLATE' -co 'ZLEVEL=9'")

## Generate a hillshade for statewide mapping
aggregate_longlat <- function(x, res, fun = 'mean'){
  scale.x <- geosphere::distGeo(c(xmin(x),mean(ymin(x),ymax(x))),
                                c(xmax(x),mean(ymin(x),ymax(x)))) %>%
    magrittr::divide_by(ncol(x))

  factor.x <- (res/scale.x) %>%
    floor()

  scale.y <- geosphere::distGeo(c(mean(xmin(x),xmax(x)),ymin(x)),
                                c(mean(xmin(x),xmax(x)),ymax(x))) %>%
    magrittr::divide_by(nrow(x))

  factor.y <- (res/scale.y) %>%
    floor()

  x.vx <- velox::velox(x)

  x.vx$aggregate(factor = c(factor.x, factor.y),
                 aggtype = fun)

  if(is(x,"RasterBrick")) return(x.vx$as.RasterBrick())
  if(is(x,"RasterStack")) return(x.vx$as.RasterStack())
  return(x.vx$as.RasterLayer(band=1))
}


swus_hillshade_500m <- raster("./Data/data-derived/swus_4C_hillshade.tif") %>%
  aggregate_longlat(res = 500) %>%
  raster::projectRaster(swus_rast_500)


# %>%
#   raster::crop(mt_counties %>%
#                  as("Spatial"),
#                snap = 'out') %>%
#   raster::mask(mt_counties %>%
#                  as("Spatial")) %>%
#   round()

swus_hillshade_500m[] <- as.integer(swus_hillshade_500m[])
raster::dataType(swus_hillshade_500m) <- "INT1U"

swus_hillshade_500m %>%
  readr::write_rds("./Data/data-derived/swus_hillshade_500m.rds")

swus_hillshade_500m <-
  readr::read_rds("./data-derived/swus_hillshade_500m.rds")

get_df <- function(x){
  out <- cbind(raster::xyFromCell(x, seq_len(raster::ncell(x))),
               tibble::tibble(ID = raster::getValues(x))) %>%
    tibble::as_tibble()

  if(is.factor(x)){

    levels <- levels(x)[[1]] %>%
      dplyr::mutate_all(.funs = list(ordered)) %>%
      tibble::as_tibble()

    fact <- out$ID %>%
      ordered(levels = levels(levels$ID))

    out %<>%
      dplyr::mutate(ID = fact) %>%
      dplyr::left_join(levels)
  }

  return(out)
}

swus_hillshade_500m %<>%
  get_df() %>%
  dplyr::mutate_all(as.integer)

usethis::use_data(swus_hillshade_500m, overwrite = TRUE)

vep_demography <- readxl::read_excel("./data-raw/vepii_demography_reconstructions.xlsx")

usethis::use_data(vep_demography, overwrite = TRUE)

