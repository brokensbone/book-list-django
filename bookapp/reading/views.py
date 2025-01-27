from django.http import HttpResponse
from django.template import loader
from django.shortcuts import get_object_or_404, render

from .models import Book, Author

def index(request):
    return HttpResponse("Hello, world. You're at the library index.")

def all_books(request):
    book_list = Book.objects.order_by("title")[:5]
    template = loader.get_template("books/listing.html")
    context = {
        "book_list": book_list,
    }
    return HttpResponse(template.render(context, request))

def author_books(request, author_id):
    author = get_object_or_404(Author, pk=author_id)
    books = Book.objects.filter(author=author)
    return render(request, "books/author_books.html", {
        "author": author,
        "book_list": books
    })
