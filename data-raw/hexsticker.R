library(cropcircles)
library(ggplot2)
library(ggimage)
library(showtext)

# choose a font from Google Fonts
font_add_google("Fira Sans", "firasans")
showtext_auto()

# R logo

R_img_cropped <- hex_crop(
  images = here::here("data-raw","R_logo.svg.png"),
  bg_fill = "#FFF",
  border_colour = "#2166bb",
  border_size = 50
)

# GitHub logo

github_img_cropped <- hex_crop(
  images = here::here("data-raw","github-mark.png"),
  bg_fill = "#FFF",
  border_colour = "#FFF",
  border_size = 15
)

# Put together in single hex

img_cropped <- hex_crop(
  images = here::here("data-raw","orange_hex.png"),
  bg_fill = "#FFF",
  border_colour = "#000",
  border_size = 18
)

ggplot() +
  xlim(0, 1) +
  ylim(0, 1) +
  geom_image(aes(x = 0.5, y = 0.5), image = img_cropped, by = "height", size=0.99) +
  geom_image(aes(x = 0.648, y = .737, image = R_img_cropped), size = 0.26) +
  geom_image(aes(x = 0.520, y = 0.512, image = R_img_cropped), size = 0.26) +
  geom_image(aes(x = 0.780, y = 0.512, image = github_img_cropped), size = 0.26) +
  annotate("text",
         x = 0.5, y = .26, label = "pkgmeta", family = "firasans", size = 24, colour = "white",
         fontface = "bold"
  ) +
  coord_cartesian(xlim = c(0,1), ylim = c(0,1), expand = FALSE) +
  theme_void()

ggsave("./man/figures/pkgmeta-hex.png", height = 2.5, width = 2.5)
