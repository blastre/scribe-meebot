from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="scribe-client",
    version="0.5.4",
    author="Scribe Team",
    author_email="support@example.com",
    description="Python client library for Scribe - privacy-first, open-source API for real-time meeting transcription",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/blastre/scribe-meetbot",
    project_urls={
        "Documentation": "https://github.com/blastre/scribe-meetbot/blob/main/docs/user_api_guide.md",
        "Bug Tracker": "https://github.com/blastre/scribe-meetbot/issues",
    },
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: Apache Software License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: Communications :: Chat",
        "Topic :: Multimedia :: Sound/Audio :: Speech",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
    ],
    python_requires=">=3.7",
    install_requires=[
        "requests>=2.25.0",
    ],
    keywords="meeting transcription translation real-time api client scribe",
    license="MIT",
) 