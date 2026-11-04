#include <filesystem>
#include <iostream>
#include <string>

#include "vendor/g4m_GUI_elements/IntToStr.cpp"
#include "vendor/g4m_GUI_elements/tableData.cpp"

int main(int argc, char* argv[]) {
    if (argc != 4) {
        std::cerr << "Usage: convert-country INPUT.gdc OUTPUT_DIR OUTPUT_STEM\n";
        return 2;
    }

    const std::filesystem::path input(argv[1]);
    const std::filesystem::path description = input.parent_path() / (input.stem().string() + ".gdt");
    if (!std::filesystem::is_regular_file(input) || !std::filesystem::is_regular_file(description)) {
        std::cerr << "Missing G4M table or description: " << input << ", " << description << '\n';
        return 1;
    }

    tableData table(input.string());
    if (!table.SaveToFileCSV(argv[2], argv[3], true)) {
        std::cerr << "Could not convert G4M country table\n";
        return 1;
    }
    return 0;
}
