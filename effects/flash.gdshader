shader_type canvas_item;

// დარტყმისას „ციმციმი“: 0 = ჩვეულებრივი ფერი, 1 = მთლიანად flash_color.
// იმუშავებს მომავალში ნახატ პერსონაჟებზეც, არა მხოლოდ მართკუთხედებზე.
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// შეფერვა (მაგ. მტერი თავდასხმის წინ წითლდება): 0 = ჩვეულებრივი ფერი, 1 = მთლიანად tint_color.
// ციმციმი შეფერვაზე მაღლა ჩანს.
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, tint_color.rgb, tint_amount);
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount);
}
