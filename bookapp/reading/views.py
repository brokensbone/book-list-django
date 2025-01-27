from django.http import HttpResponse
from django.template import loader

from .models import Book

def index(request):
    return HttpResponse("Hello, world. You're at the library index.")

def listing(request):
    book_list = Book.objects.order_by("title")[:5]
    template = loader.get_template("books/listing.html")
    context = {
        "book_list": book_list,
    }
    return HttpResponse(template.render(context, request))
