require 'json'
require 'faraday'

deck_template = <<HTML
<html>
<head>
<script src="https://code.jquery.com/jquery-3.1.0.min.js"></script>
<title>###TITLE###</title>
<style>
body {
  padding: 0;
  margin: 0;
}
h1 {
  padding: 0;
  margin: 0;
}
.slide {
  height: 100%;
  width: 100%;
  text-align: center;
}
.slide>h1 {
  height: 10%;
}
.slide>img {
  height: 90%;
}
</style>
</head>
<body>
###SLIDES###
<script>
var counter = 0;
window.onload = function() {
  alert('Presentation loaded!');
  $('.slide').hide();
  $('#slide0').show();
};
$(document).keydown(function(e) {
  $('.slide').hide();
  if (e.which == 37) {
    counter = counter == 0 ? 0 : counter - 1;
  } else {
    counter = counter == ($('.slide').length - 1) ? counter : counter + 1;
  }
  $('#slide' + counter).show();
});
</script>
</body>
</html>
HTML

slide_template = <<HTML
<div class="slide" id="###GIFID###">
<h1>###GIFTITLE###</h1>
<img src="###GIFURL###" />
</div>
HTML

conn = Faraday.new(url: 'https://api.giphy.com') do |faraday|
  faraday.request  :url_encoded
  faraday.adapter  Faraday.default_adapter
end

puts '[+] Reading slide data...'
deck_data = File.read('slides.txt').split("\n")

puts '[+] Requesting gifs...'
slides = ''
deck_data.each_with_index do |slide_title, index|
  response = conn.get '/v1/gifs/search', { api_key: 'dc6zaTOxFJmzC', q: slide_title }
  giphy = JSON.parse(response.body)
  if giphy['pagination']['total_count'] > 0
    gif = giphy['data'][0]['images']['fixed_height']['url']
  else
    response = conn.get '/v1/gifs/random', { api_key: 'dc6zaTOxFJmzC' }
    giphy = JSON.parse(response.body)
    gif = giphy['data']['image_original_url']
  end
  puts "[+} Generating slide #{index}..."
  slides += slide_template.gsub('###GIFURL###', gif)
                          .gsub('###GIFID###', "slide#{index}")
                          .gsub('###GIFTITLE###', slide_title)
end

puts '[+] Generating deck from template...'
deck_template.gsub!('###TITLE###', deck_data[0])
deck_template.gsub!('###SLIDES###', slides)
File.write('slides.html', deck_template)
