from django.urls import path

from . import views

urlpatterns = [
    path("", views.index, name="index"),
    path("books", views.all_books, name="listing"),
    path("authors/<int:author_id>/", views.author_books, name="author"),
]