### Ü blog

<ul>
	{% for post in site.posts %}
		<li>
			<a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
		</li>
	{% endfor %}
</ul>

### Other publications

Habr (russian), in retrochronological order:

[Реализация генераторов в языке программирования Ü](https://habr.com/ru/articles/733088/)

[Язык програмирования Ü — нелёгкий путь написания самодостаточного компилятора](https://habr.com/ru/articles/580024/)

[Язык программирования Ü. Введение, мотивация к созданию, цели](https://habr.com/ru/articles/465553/)

[Thread](https://gamedev.ru/flame/forum/?id=230610) of the project GameDev.ru (russian)
