library(magrittr)
library(tidycensus)

# A nice projection for the Four Corners states
nm <- tigris::states(
  class = "sf",
  progress_bar = FALSE
) %>%
  dplyr::filter(NAME == "New Mexico") %>%
  sf::st_transform(4326) %>%
  sf::st_bbox()

co <- tigris::states(
  class = "sf",
  progress_bar = FALSE
) %>%
  dplyr::filter(NAME == "Colorado") %>%
  sf::st_transform(4326) %>%
  sf::st_bbox()

four_corners_lcc_proj <- paste0(
  "+proj=lcc",
  " +lat_1=", co[["ymax"]],
  " +lat_2=", nm[["ymax"]] - (co[["ymax"]] - co[["ymin"]]),
  " +lat_0=", nm[["ymax"]],
  " +lon_0=", nm[["xmin"]],
  " +x_0=", nm[["xmin"]],
  " +x_y=", nm[["xmin"]]
)
usethis::use_data(four_corners_lcc_proj, overwrite = TRUE)

four_corners_states <-
  tigris::states(
    class = "sf",
    progress_bar = FALSE
  ) %>%
  dplyr::filter(NAME %in% c(
    "Arizona", "Colorado",
    "New Mexico", "Utah"
  )) %>%
  smoothr::densify(max_distance = 0.01) %>%
  sf::st_transform(four_corners_lcc_proj) %>%
  dplyr::select(STATEFP, STUSPS) %>%
  dplyr::rename(State = STUSPS)

usethis::use_data(four_corners_states, overwrite = TRUE)

## Get the VEP II study area definitions from the `villager` package.
## https://github.com/village-ecodynamics/villager
vepii_cmv_boundary <- villager::vepii_cmv_boundary
vepii_nrg_boundary <- villager::vepii_nrg_boundary

# VEP study areas
vep_study_areas <-
  list(
    CMV = vepii_cmv_boundary,
    NRG = vepii_nrg_boundary
  ) %>%
  purrr::map(smoothr::densify,
    max_distance = 100
  ) %>%
  purrr::map(sf::st_transform,
    crs = four_corners_lcc_proj
  ) %>%
  purrr::imap(~ dplyr::mutate(.x, `Study Area` = .y)) %>%
  do.call(rbind, .)

usethis::use_data(vep_study_areas, overwrite = TRUE)

## Create the Upland US Southwest boundary
## The boundary is defined as a geographic rectangle sans Maricopa, Pinal, and Pima counties
uusw_boundary <-
  sf::st_bbox(c(
    xmin = -113,
    xmax = -105,
    ymin = 32,
    ymax = 38
  ),
  crs = 4326
  ) %>%
  sf::st_as_sfc() %>%
  smoothr::densify(max_distance = 0.01) %>%
  sf::st_transform(four_corners_lcc_proj)

usethis::use_data(uusw_boundary, overwrite = TRUE)



uusw_counties <-
  tigris::counties(
    cb = TRUE,
    class = "sf",
    progress_bar = FALSE
  ) %>%
  smoothr::densify(max_distance = 0.01) %>%
  sf::st_transform(four_corners_lcc_proj) %>%
  dplyr::filter(sf::st_intersects(suppressWarnings(sf::st_centroid(.)),
    uusw_boundary %>%
      sf::st_transform(four_corners_lcc_proj),
    sparse = FALSE
  )) %>%
  dplyr::select(NAME, STATEFP) %>%
  dplyr::rename(County = NAME) %>%
  dplyr::filter(!(County %in% c(
    "Maricopa",
    "Pima",
    "Pinal"
  ))) %>%
  dplyr::left_join(four_corners_states %>%
    sf::st_drop_geometry(),
  by = "STATEFP"
  ) %>%
  dplyr::select(-STATEFP) %>%
  tidyr::unite(col = County, County, State, sep = ", ")

usethis::use_data(uusw_counties, overwrite = TRUE)



## Create a nice hillshade for the Four Corners states for mapping
# Define the Four Corners states
# "https://prd-tnm.s3.amazonaws.com/StagedProducts/Small-scale/data/Boundaries/statesp010g.gdb_nt00937.tar.gz" %>%
#   download.file(destfile="../Data/data-raw/statesp010g.gdb_nt00937.tar.gz",
#                 mode='wb')
# untar("../Data/data-raw/statesp010g.gdb_nt00937.tar.gz",
#       exdir="../Data/data-raw/statesp010g")

swus_rast_500 <- raster::raster(raster::extent(-562000, 642000, -648500, 585000),
  res = 500,
  # nrows = 2467,
  # ncols = 2408,
  crs = CRS(four_corners_lcc_proj)
)

swus_ned <- FedData::get_ned(
  template = four_corners_states %>%
    sf::st_union() %>%
    sf::st_buffer(20000) %>%
    as("Spatial"),
  label = "swus_4C",
  raw.dir = "~/Dropbox/EntropyRegimeChange/Data/data-raw/ned/",
  extraction.dir = "~/Dropbox/EntropyRegimeChange/Data/data-raw/"
)

system("gdaldem hillshade ~/Dropbox/EntropyRegimeChange/Data/data-raw/swus_4C_NED_1.tif ~/Dropbox/EntropyRegimeChange/Data/data-derived/swus_4C_hillshade.tif -z 2 -s 111120 -multidirectional -co 'COMPRESS=DEFLATE' -co 'ZLEVEL=9'")

## Generate a hillshade for statewide mapping
aggregate_longlat <- function(x, res, fun = "mean") {
  scale.x <- geosphere::distGeo(
    c(xmin(x), mean(ymin(x), ymax(x))),
    c(xmax(x), mean(ymin(x), ymax(x)))
  ) %>%
    magrittr::divide_by(ncol(x))

  factor.x <- (res / scale.x) %>%
    floor()

  scale.y <- geosphere::distGeo(
    c(mean(xmin(x), xmax(x)), ymin(x)),
    c(mean(xmin(x), xmax(x)), ymax(x))
  ) %>%
    magrittr::divide_by(nrow(x))

  factor.y <- (res / scale.y) %>%
    floor()

  x.vx <- velox::velox(x)

  x.vx$aggregate(
    factor = c(factor.x, factor.y),
    aggtype = fun
  )

  if (is(x, "RasterBrick")) {
    return(x.vx$as.RasterBrick())
  }
  if (is(x, "RasterStack")) {
    return(x.vx$as.RasterStack())
  }
  return(x.vx$as.RasterLayer(band = 1))
}


swus_hillshade_500m <- raster("~/Dropbox/EntropyRegimeChange/Data/data-derived/swus_4C_hillshade.tif") %>%
  aggregate_longlat(res = 500) %>%
  raster::projectRaster(swus_rast_500)

swus_hillshade_500m[] <- as.integer(swus_hillshade_500m[])
raster::dataType(swus_hillshade_500m) <- "INT1U"

swus_hillshade_500m %>%
  readr::write_rds("~/Dropbox/EntropyRegimeChange/Data/data-derived/swus_hillshade_500m.rds")

swus_hillshade_500m <-
  readr::read_rds("~/Dropbox/EntropyRegimeChange/Data/data-derived/swus_hillshade_500m.rds")

get_df <- function(x) {
  out <- cbind(
    raster::xyFromCell(x, seq_len(raster::ncell(x))),
    tibble::tibble(ID = raster::getValues(x))
  ) %>%
    tibble::as_tibble()

  if (is.factor(x)) {
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
  raster::crop(four_corners_states, snap = "out") %>%
  raster::mask(four_corners_states) %>%
  get_df() %>%
  dplyr::mutate_all(as.integer)

usethis::use_data(swus_hillshade_500m, overwrite = TRUE)




vep_demography <- readxl::read_excel("./data-raw/vepii_demography_reconstructions.xlsx")

usethis::use_data(vep_demography, overwrite = TRUE)
