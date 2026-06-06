from hello import greet


def test_greet_default():
    assert greet() == "Hello, everyone!"


def test_greet_custom():
    assert greet("GitHub Actions") == "Hello, GitHub Actions!"
