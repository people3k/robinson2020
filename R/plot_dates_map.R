packages <- c("magrittr",
              "tidyverse",
              "googledrive",
              "sf",
              "lwgeom",
              "units"
) 
# purrr::walk(packages, devtools::install_cran) %>%
purrr::walk(packages,
            library, 
            character.only = TRUE)

source("./R/get_df.R")

# A nice projection for the Four Corners states
four_corners_lcc_proj <- "+proj=lcc +lat_1=37 +lon_0=-109.045225"

# Define the Bocinsky et al. 2016 study area
SWUS_bbox <- sf::st_bbox(c(xmin = -113,
                           xmax = -105,
                           ymin = 32,
                           ymax = 38), 
                         crs = 4326) %>%
  sf::st_as_sfc() %>%
  sf::st_set_crs(NA) %>%
  sf::st_segmentize(dfMaxLength = 0.01) %>%
  sf::st_set_crs(4326) %>%
  sf::st_transform(four_corners_lcc_proj)

# Define the Four Corners states
# "https://prd-tnm.s3.amazonaws.com/StagedProducts/Small-scale/data/Boundaries/statesp010g.gdb_nt00937.tar.gz" %>%
#   download.file(destfile="../Data/data-raw/statesp010g.gdb_nt00937.tar.gz",
#                 mode='wb')
# untar("../Data/data-raw/statesp010g.gdb_nt00937.tar.gz",
#       exdir="../Data/data-raw/statesp010g")
four_corners_states <- "./Data/data-raw/statesp010g/statesp010g.gdb/" %>%
  sf::st_read() %>%
  dplyr::filter(NAME %in% 
                  c("Arizona",
                    "Colorado",
                    "New Mexico",
                    "Utah")) %>%
  sf::st_transform(four_corners_lcc_proj)

swus_hillshade_500m <- readr::read_rds("./Data/data-derived/swus_hillshade_500m.rds") %>%
  raster::crop(four_corners_states) %>%
  raster::mask(four_corners_states)

dendro_data <- sf::read_sf("./Data/data-derived/dendro_data.geojson") %>%
  sf::st_transform(four_corners_lcc_proj) %>%
  dplyr::filter(Date_BP >= 550,
                Date_BP <= 1450) %>%
  dplyr::group_by(Site_Number) %>%
  dplyr::summarise(Date_BP = mean(Date_BP, na.rm = T),
                   geometry = mean(geometry)) %>%
  dplyr::mutate(`Date Type` = "Dendro") %>%
  dplyr::select(-Site_Number) %>%
  sf::st_centroid()

radiocarbon_data <- sf::read_sf("./Data/data-derived/radiocarbon_data.geojson") %>%
  sf::st_transform(four_corners_lcc_proj) %>%
  dplyr::filter(Date_BP >= 550,
                Date_BP <= 1450) %>%
  dplyr::group_by(Site_Number) %>%
  dplyr::summarise(Date_BP = mean(Date_BP, na.rm = T)) %>%
  sf::st_jitter(20000) %>%
  dplyr::mutate(`Date Type` = "C14") %>%
  dplyr::select(-Site_Number) %>%
  sf::st_centroid()

dates <- rbind(dendro_data,
               radiocarbon_data)

# ggplot(dates) +
#   geom_sf(data = dates,
#           mapping = aes(shape = `Date Type`),
#           show.legend = "point")

ggplot() + 
  geom_sf(data = four_corners_states) +
  ggplot2::geom_raster(data = swus_hillshade_500m %>%
                         get_df(),
                       mapping = aes(x = x,
                                     y = y,
                                     alpha = ID),
                       na.rm = TRUE) +
  scale_alpha(range = c(0.8, 0),
              na.value = 0,
              limits = c(0,255),
              guide = "none") +
  geom_sf(data = four_corners_states,
          fill = NA) +
  geom_sf(data = SWUS_bbox,
          fill = NA) +
  geom_sf(data = dates,
          mapping = aes(shape = `Date Type`,
                        color = Date_BP),
          show.legend = "point") +
  scale_shape(
    name = 'Date Type',
    solid = FALSE,
    guide = guide_legend(position = "top",
                         direction = "horizontal",
                         title.position = "top",
                         label.position = "bottom")
  ) +
  viridis::scale_color_viridis(
    name = 'Year BP',
    limits = c(450,1450),
    breaks = c(450,1450),
    direction = -1,
    guide = guide_colorbar(position = "top",
                           direction = "horizontal",
                           title.position = "top",
                           label.position = "bottom",
                           reverse = TRUE)) +
  mdt_theme_map(16)

ggsave('./swus_sample_map.pdf',
       height = 8,
       width = 6)
