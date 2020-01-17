packages <- c("magrittr",
              "tidyverse",
              "googledrive",
              "sf",
              "lwgeom",
              "units",
              "rcarbon",
              "villager"
)
# devtools::install_github("benmarwick/rrtools")
# devtools::install_github("village-ecodynamics/villager")

# purrr::walk(packages, devtools::install_cran)
purrr::walk(packages,
            library, 
            character.only = TRUE)

# VEP study areas
vep_study_areas <- 
  list(CMV = villager::get_vep_boundary(version = "vepii_cmv"),
       NRG = villager::get_vep_boundary(version = "vepii_nrg")) %>%
  purrr::map(sf::st_transform,
             crs = 4326) %>%
  purrr::map(tibble::as_tibble) %>%
  dplyr::bind_rows(.id = "Study Area") %>%
  sf::st_as_sf(crs = 4326)

#SPDs for SW region overlapping Bocinsky et al. 2016 dendro cutting date database
radiocarbon_data <-
  sf::read_sf("./data-derived/radiocarbon_data.geojson") %>%
  dplyr::mutate(Type = "Radiocarbon",
                SiteID = SiteID %>% stringr::str_c("Radiocarbon - ", .)) %>%
  dplyr::mutate(`Study Area` = ifelse(County == "Montezuma, CO",
                                      "CMV", 
                                      NA),
                `Study Area` = ifelse(County %in% c("Rio Arriba, NM",
                                                    "Sandoval, NM",
                                                    "Santa Fe, NM",
                                                    "Taos, NM"),
                                      "NRG", 
                                      `Study Area`)) %>%
  dplyr::select(-County)

# We can do many of the same things for the tr dates
dendro_data <- 
  sf::read_sf("./data-derived/dendro_data.geojson") %>%
  dplyr::mutate(Type = Type %>% stringr::str_c("Dendro - ", .),
                SiteID = SiteID %>% stringr::str_c("Dendro - ", .),
                SD = 0) %>%
  dplyr::filter(Type == "Dendro - Cutting or Near-cutting") %>%
  dplyr::mutate(Type = "Tree-ring") %>%
  sf::st_join(vep_study_areas) %>%
  dplyr::select(-Site_Name) %>%
  # dplyr::rename(`Study Area` = `Study.Area`) %>%
  dplyr::select(names(radiocarbon_data))

rbind(radiocarbon_data,
      dendro_data) %>%
  sf::st_drop_geometry() %>%
  group_by(Type,`Study Area`) %>%
  dplyr::summarise(Count = n()) %>%
  tidyr::spread(Type, Count)

radiocarbon_spd <-
  radiocarbon_data %>%
  split(.,.$`Study Area`) %>%
  tibble::tibble(`Study Area` = names(.),
                 Dates = .) %>%
  dplyr::bind_rows(tibble::tibble(`Study Area` = "UUSW",
                                  Dates = list(radiocarbon_data))) %>%
  dplyr::rowwise() %>%
  dplyr::mutate(Calibrated = list(Dates %$%
                                    rcarbon::calibrate(x = Date_BP,
                                                       errors = SD,
                                                       calMatrix = TRUE,
                                                       normalised = TRUE)),
                Bins = list(rcarbon::binPrep(sites = Dates$SiteID,
                                             ages = Calibrated,
                                             h = 100)),
                SPD = list(spd(x = Calibrated,
                               bins = Bins,
                               timeRange = c(1949,0),
                               runm = 21))) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(Density = SPD %>%
                  purrr::map(function(x){
                               x$grid %>%
                                 tibble::as_tibble() %$%
                                 tibble::tibble(Type = "Radiocarbon Density",
                                                Date_BP = calBP,
                                                Density = PrDens / sum(PrDens, na.rm = T))
                             })
  ) %T>%
  readr::write_rds("./data-derived/radiocarbon_spd.rds",
                   compress = "gz")

radiocarbon_spd <- readr::read_rds("./data-derived/radiocarbon_spd.rds")


calibrate_tree_ring_dates <- function(x){
  out <- list(
    metadata = tibble::tibble(
      DateID = 1:length(x),
      CRA = x,
      Error = 0,
      Details = NA,
      CalCurve = "intcal13",
      ResOffsets = 0,
      ResErrors = 0,
      StartBP = 50000,
      EndBP = 0,
      Normalised = TRUE,
      F14C = FALSE,
      CalEPS = 1e-05
    ),
    grids = NA,
    calmatrix = 
      tibble::tibble(index = 1:length(x),
                     year_bp = x,
                     value = TRUE) %>%
      tidyr::pivot_wider(names_from = index,
                         values_from = value) %>%
      dplyr::bind_rows(tibble::tibble(year_bp = 50000:0)) %>%
      dplyr::filter(!duplicated(year_bp)) %>%
      dplyr::arrange(-year_bp) %>%
      dplyr::filter(year_bp >= 0) %>%
      tibble::column_to_rownames("year_bp") %>%
      as.matrix() %>%
      tidyr::replace_na(0) %>%
      magrittr::set_colnames(NULL)
  )
  
  attr(out,"class") <- c("CalDates", "list")
  
  return(out)
}

dendro_spd <-
  dendro_data %>%
  split(.,.$`Study Area`) %>%
  tibble::tibble(`Study Area` = names(.),
                 Dates = .) %>%
  dplyr::bind_rows(tibble::tibble(`Study Area` = "UUSW",
                                  Dates = list(dendro_data))) %>%
  dplyr::rowwise() %>%
  dplyr::mutate(Calibrated = list(Dates %$%
                                    calibrate_tree_ring_dates(x = Date_BP)),
                Bins = list(rcarbon::binPrep(sites = Dates$SiteID,
                                             ages = Dates$Date_BP,
                                             h = 100)),
                SPD = list(spd(x = Calibrated,
                               bins = Bins,
                               timeRange = c(1949,0),
                               runm = 21))) %>%
  
  dplyr::ungroup() %>%
  dplyr::mutate(Density = SPD %>%
                  purrr::map(function(x){
                    x$grid %>%
                      tibble::as_tibble() %$%
                      tibble::tibble(Type = "Tree-ring Density",
                                     Date_BP = calBP,
                                     Density = PrDens / sum(PrDens, na.rm = T))
                  })
  ) %T>%
  readr::write_rds("./data-derived/dendro_spd.rds",
                   compress = "gz")

dendro_spd <- readr::read_rds("./data-derived/dendro_spd.rds")



# dendro_density <- 
#   dendro_data %>%
#   dplyr::filter(!is.na(`Study Area`)) %>%
#   rbind(dendro_data %>%
#           dplyr::mutate(`Study Area` = "UUSSW")) %>%
#   sf::st_drop_geometry() %>%
#   group_by(`Study Area`,Bins) %>%
#   dplyr::summarize(Density = list(density(Date_BP,
#                                           bw = 10,
#                                           from = 1949,
#                                           to = -45,
#                                           n = 1995) %$%
#                                     tibble::tibble(Date_BP = x,
#                                                    Density = y / sum(y, na.rm = T)))) %>%
#   tidyr::unnest(cols = c(Density)) %>%
#   dplyr::mutate(Type = "Tree-ring Density")

all_density <- dendro_spd %>%
  dplyr::select(`Study Area`,Density) %>%
  tidyr::unnest(cols = c(Density)) %>%
  bind_rows(radiocarbon_spd %>%
              dplyr::select(`Study Area`,Density) %>%
              tidyr::unnest(cols = c(Density))) %>%
  dplyr::mutate(`Year AD` = 1950 - Date_BP) %>%
  dplyr::select(`Year AD`,
                Date_BP,
                `Study Area`,
                Type, 
                Density) %>%
  dplyr::rename(Value = Density)# %>%
  # dplyr::filter(`Year AD` %in% 600:1650) %>%
  # dplyr::group_by(`Study Area`,
  #                 Type) %>%
  # dplyr::mutate(Value = Value / sum(Value, na.rm = T)) %>%
  # dplyr::ungroup()

vep_demography <- 
  readxl::read_excel("./data-raw/vepii_demography_reconstructions.xlsx") %>%
  dplyr::rowwise() %>%
  dplyr::mutate(`Year AD` = list((Start+1):End)) %>%
  dplyr::select(`Study Area`,`Year AD`,Population) %>%
  tidyr::unnest(cols = c(`Year AD`)) %>%
  dplyr::mutate(Type = "Population",
                Date_BP = 1950 - `Year AD`) %>%
  dplyr::rename(Value = Population)





all_density %>%
  dplyr::bind_rows(vep_demography) %>%
  dplyr::mutate(Type = factor(Type, 
                              levels = c("Radiocarbon Density",
                                         "Tree-ring Density",
                                         "Population"),
                              ordered = TRUE)#,
                # `Study Area` = ifelse(`Study Area` == "CMV", "Central Mesa Verde", "Northern Rio Grande")
  ) %>%
  ggplot(aes(x = `Year AD`)) +
  geom_line(aes(y = Value,
                color = `Study Area`),
            size = 1.25) +
  # coord_cartesian(xlim = c(600,1600)) +
  xlab("Year AD") +
  theme_minimal(24) +
  theme(legend.title = element_blank(),
        legend.justification = c(0, 1), 
        legend.position = "bottom",
        axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        plot.margin=unit(c(0.25,0.5,0.25,0.25),"in")
  ) +
  ggplot2::facet_wrap("Type", 
                      nrow = 3,
                      scales = "free_y")




ggsave("./output/c14_tr_pop.pdf",
       height = 10,
       width = 10)

