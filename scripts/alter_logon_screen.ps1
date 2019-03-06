# requires imagemagick to be installen (and added to PATH)

# background images are located here: C:\Windows\Web\Screen


magick convert -font arial -fill black -pointsize 120 -draw "rectangle 100,100, 1000,240" img100.jpg img100.jpg
magick convert -font arial -fill white -pointsize 120 -draw "text 100,200 'Schnappie'" img100.jpg img100.jpg