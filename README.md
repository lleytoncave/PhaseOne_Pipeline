<div style="font-family: Arial, sans-serif;">

# Phase One Imagery processing pipeline

![Project Status](https://img.shields.io/badge/status-ACTIVE-6f901e)
<!-- Status last updated: 2025-11-29 06:20:39 UTC | Commits last week: 6 -->

A pipeline to process imagery from the phase one camera. This system has a high resolution rgb camera and generates a large amount of data that needs to be handled efficiently. 


## Project Information

**Project Code:** [Insert APPN project code]

**Project Title:** [Phase One Pipeline]

**Start Date:** [2025-10-13]

**End Date:** [NA]  

## Project Description

[A pipeline to process imagery from the phase one camera. This system has a high resolution rgb camera and generates a large amount of data that needs to be handled efficiently. The pipeline outline consists of a few steps:

1 - Downsamples of raw iiq files while maintaining all metadata. This step is done using Imagemagick which natively supports IIQ image files from the phase one.

2 - Run downsampled images through agisoft to align cameras and estimate extrinsic and intrinsic camera parameters for reverse calculation of the plot boundaries from the raw images

3 - To implement with code from Lukas using the Phase One SDK to optimise denoising and resolution. In this step will specify plot bounds from agisoft output adjusting for dowsampling in step 1.

4 - This should hopefully generate high resoltuion plot clip photos for tasks like object detection and segmentation with a known area or gsd that can allow calculation of traits with a refernce to area, ex. Plants per m2.]


<!-- PROJECT_TREE_START -->
<h2>Project structure</h2>

```plaintext
.
├── LICENSE
├── README.md
├── assets
│   ├── APPN_logo.png
│   ├── docx_example_30072025.png
│   └── html_example_30072025.png
├── code
│   ├── iiqp.ps1
│   ├── phaseone_processing-main(1).zip
│   ├── revcalc.py
│   └── summary.txt
├── project_tree_structure.txt
└── quarto-report
    ├── How-to-use-QMD.md
    ├── Template.qmd
    ├── _extensions
    │   └── appn-report
    │       ├── _extension.yml
    │       ├── assets
    │       ├── filters
    │       ├── header.tex
    │       ├── partials
    │       └── references.bib
    └── docs
        ├── docx
        │   └── Template.docx
        └── html
            └── Template.html

12 directories, 17 files
```
<!-- PROJECT_TREE_END -->

## Data Management

[No associated data]

## Installation and Setup

To set up the project environment, follow these steps:

[Provide instructions for setting up the project environment, including dependencies and configurations]
To add full list (Dependencies: ImageMagick, Phase one SDK, Agisoft Metashape).

## Usage

[Provide instructions on how to run your analysis]


## Contact

**APPN UQ:** appn@uq.edu.au
**Lleyton Cave:** l.cave@uq.edu.au

## Acknowledgments

This research is supported by the Australian Plant Phenomics Network (APPN) and The University of Queensland. We acknowledge the use of the facilities, and scientific and technical assistance of APPN, which is supported by the Australian Government's National Collaborative Research Infrastructure Strategy (NCRIS). The APPN Quarto templates were developed using background information from the Analytics for the Australian Grains Industry (AAGI) https://github.com/AAGI-AUS. 


![APPN Logo](assets/APPN_logo.png)


---

**Template Version:** APPN UQ Template v2.0 August 2025  
**Maintained by:** APPN UQ Team

</div>


