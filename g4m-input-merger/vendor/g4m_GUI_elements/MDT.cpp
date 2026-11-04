#include "MDT.h"

// Default constructor
MDT::MDT()
{
	nDims = 0;
}

// Constructor from file
MDT::MDT(string fileName)
{
	ifstream f;
	f.open(fileName.c_str(), ios::in);
	if (f.is_open())
	{
		string line;
		// Reading number of dimensions and parameter description:
		getline(f,line);
		stringstream s(line);
		s >> nDims;
		dimCardinals.resize(nDims);
		dimNames.resize(nDims);
		dimElements.resize(nDims);
		while (s >> line) paramName += line + " ";
		paramName.erase(paramName.length()-1);
		// Reading dimensions' descriptions:
		for (int i = 0; i < nDims; i++)
		{
			getline(f, line);
			stringstream ss(line);
			int tmp;
			ss >> tmp;
			dimCardinals[i] = tmp;
			while (ss >> line) dimNames[i] += line + " ";
			dimNames[i].erase(dimNames[i].length()-1);
			for (int j = 0; j < tmp; j++)
			{
				getline(f, line);
				dimElements[i].push_back(line);
			}
		}
		setHashOffsets();
		//cout << paramName << " has " << nDims << " dimensions." << endl;
		//for (int i = 0; i < nDims; i++) {
		//  cout << dimNames[i] << " has " << dimCardinals[i] << " elements:" << endl;
		//  for (int j = 0; j < dimCardinals[i]; j++) {
		//    cout << "\t" << dimElements[i][j] << endl;
		//  }
		//}
		f.close();
		cout << "Successfully read file: " << fileName << endl;
	}
	else
	{
		cout << "Unable to open file!" << endl;
	}
}

// Constructor from *.gdt file and int vector with dimensions info
MDT::MDT(string fileName, int_vector_t dimCardinalsIn)
{
	ifstream f;
	f.open(fileName.c_str(), ios::in);
	if (f.is_open())
	{
		nDims = dimCardinalsIn.size();
		dimCardinals = dimCardinalsIn;
		dimNames.resize(nDims);
		dimElements.resize(nDims);

		string line;
		getline(f, line);
		rename(line);

		for (int i = 0; i < nDims; i++)
		{
			getline(f, line);
			dimNames[i] = line;
			for (int j = 0; j < dimCardinals[i]; j++)
			{
				getline(f, line);
				dimElements[i].push_back(line);
			}
		}
		setHashOffsets();

		f.close();
	}
	else
	{
		cout << "Unable to open file!" << endl;
	}
}

// Copy constructor
MDT::MDT(const MDT & other)
{
	dimCardinals = other.dimCardinals;
	hashOffsets = other.hashOffsets;
	dimNames = other.dimNames;
	dimElements = other.dimElements;
	paramName = other.paramName;
	nDims = other.nDims;
}

// Assignment operator
MDT & MDT::operator = (const MDT & other)
{
	if (this != &other)
	{
		dimCardinals = other.dimCardinals;
		hashOffsets = other.hashOffsets;
		dimNames = other.dimNames;
		dimElements = other.dimElements;
		paramName = other.paramName;
		nDims = other.nDims;
	}
	return *this;
}

// Destructor
MDT::~MDT()
{

}

//================
// Class methods:
//================

void MDT::clear()
{
	paramName = "";
	nDims = 0;
	dimCardinals.clear();
	dimNames.clear();
	dimElements.clear();
	hashOffsets.clear();
}

void MDT::rename(string name)
{
	paramName = name;
}

bool MDT::addDim(string dimName, str_vector_t elements)
{
	for (int i = 0; i < nDims; i++)
	{
		if (dimNames[i] == dimName)      // verifying if a dimension with the specified name exists;
		{
			return false;                  // if exists, return false;
		}
	}
	nDims++;
	dimNames.push_back(dimName);
	dimCardinals.push_back(elements.size());
	dimElements.push_back(elements);
	setHashOffsets();
	return true;
}

bool MDT::addDimEl(string dimName, string element)
{
	bool dimExists = false;
	for (int i = 0; i < nDims; i++)
	{
		if (dimNames[i] == dimName)            // verifying if a dimension with the specified name exists;
		{
			dimExists = true;
			bool elementExists = false;
			for (int j = 0; j < dimElements[i].size(); j++)
			{
				if (dimElements[i][j] == element) elementExists = true;
			}										// verifying if an element with the specified name exists within dimension;
			if (elementExists)						// if exists, don't add new element and return false;
			{
				 return false;
			}
			else
			{                                 // else - add new element
				dimCardinals[i]++;
				dimElements[i].push_back(element);
				setHashOffsets();
				return true;
			}
		}
	}
	if (!dimExists)					// if a dimension with the specified name doesn't exist, add new dimension
	{
		str_vector_t tmp;
		tmp.push_back(element);
		addDim(dimName, tmp);
		return true;
	}
	return false;
}

bool MDT::updateDimEl(string dimName, int posEl, string element)
{
	bool dimExists = false;
	for (int i = 0; i < nDims; i++)
	{
		if (dimNames[i] == dimName)            // verifying if a dimension with the specified name exists;
		{
			dimExists = true;
			bool elementExists = false;

            if (posEl>=dimElements[i].size())
             {
                cout<<"There are only "<<dimElements[i].size()<<" elements. Check position of the element to be updated!"<<endl;
                return false;
              }  
                                            
			for (int j = 0; j < dimElements[i].size(); j++)
			{
//cout<<"dimElements["<<i<<"]["<<j<<"]=\t"<<dimElements[i][j]<<"\telement=\t"<<element<<endl;
				if (dimElements[i][j] == element) 
                 {  
                  elementExists = true;
				  cout<<"Such element already exists! The element is not updated"<<endl;
                 }
			}										// verifying if an element with the specified name exists within dimension;
			if (elementExists)						// if exists, don't add new element and return false;
			{
				 return false;
			}
			else
			{                                 // else - update the element
//cout<<"before update dimElements["<<i<<"]["<<posEl<<"]=\t"<<dimElements[i][posEl]<<"\telement=\t"<<element<<endl;
                dimElements[i][posEl] = element;
//cout<<"after update dimElements["<<i<<"]["<<posEl<<"]=\t"<<dimElements[i][posEl]<<"\telement=\t"<<element<<endl;
				return true;
			}
		}
	}
	if (!dimExists)					// if a dimension with the specified name doesn't exist, "error message"
	{
        cout<<"The dimension "<<dimName<<" doesn't exist. The element is not updated!!!"<<endl;
		return true;
	}
	return false;
}

long long MDT::getN()
{
	long long res = 1;
	for (int i = 0; i < nDims; i++)
	{
		res *= dimCardinals[i];
	}
	return res;
}
 
int MDT::getNDims()
{
	return nDims;
}

long long MDT::getHash(str_vector_t elements)
{
	if (nDims < elements.size())
	{
		for (int i = nDims; i < elements.size(); i++)
		{
			addDimEl("Dimension " + IntToStr(i + 1), elements[i]);
		}
	}
	int N = 1;
	int tmp = getCoordinate(0, elements[0]);
	if (tmp == -1) return -1;
	long long res = 0;
	res += N * tmp;
	for (int i = 1; i < nDims; i++)
	{
		N *= dimCardinals[i-1];
		tmp = getCoordinate(i, elements[i]);
		if (tmp == -1) return -1;
		res += N * tmp;
	}
	return res;
}

long long MDT::getHashByCoords(int_vector_t coords)
{
	long long res = coords[0];
	long long n = 1;
	for (int i = 1; i < nDims; i++)
	{
		n *= dimCardinals[i-1];
		res += n * coords[i];
	}
	return res;
}

MDT::int_vector_t MDT::getCoordsByHash(long long hashValue)
{
	int_vector_t result;
	result.resize(nDims);
	result[nDims-1] = (hashValue - (hashValue % hashOffsets[nDims-1])) / hashOffsets[nDims-1];
	hashValue -= result[nDims-1] * hashOffsets[nDims-1];
	for (int i = nDims-2; i >= 0; i--)
	{
		result[i] = (hashValue - (hashValue % hashOffsets[i])) / hashOffsets[i];
		hashValue -= result[i] * hashOffsets[i];
	}
	return result;
}

int MDT::getCoordinate(int dim, string element)
{
	for (int i = 0; i < dimElements[dim].size(); i++)
	{
		if (dimElements[dim][i] == element) return i;
	}
	dimElements[dim].push_back(element);
	dimCardinals[dim]++;
	return (dimElements[dim].size() - 1);
}

void MDT::SaveToFile(string fileName, string mode)
{
	ofstream f;
	if (mode == "MAP") fileName += ".mdt";
	printf("Writing mdt\n%d dimension(s)\n", nDims);
	for (int i = 0; i < dimNames.size(); i++)
	{
		cout << dimNames[i] << " - " << dimCardinals[i] << endl;
	}
	f.open(fileName.c_str(), ios::out);
	if (f.is_open())
	{
		if (mode == "MAP")
		{
			f << nDims << " " << paramName << endl;
			for (int i = nDims - 1; i >= 0; i--)
			{
				f << dimCardinals[i] << " " << dimNames[i] << endl;
				for (int j = 0; j < dimCardinals[i]; j++)
				{
					f << dimElements[i][j] << endl;
				}
			}
			cout << "Successfully written to file: " << fileName << endl;
		}
		else if (mode == "TABLE")
		{
			f << paramName << endl;
			for (int i = 0; i < nDims; i++)
			{
				f << dimNames[i] << endl;
				for (int j = 0; j < dimCardinals[i]; j++)
				{
					f << dimElements[i][j] << endl;
				}
			}
			cout << "Successfully written to file: " << fileName << endl;
		}
		else
		{
			cout << "Error writing to file! Wrong mode!" << endl;
		}
		f.close();
	}
	else
	{
		cout << "Unable to save to file: " << fileName << endl;
	}
}

void MDT::setHashOffsets()
{
	hashOffsets.resize(nDims);
	hashOffsets[0] = 1;
	for (int i = 1; i < nDims; i++)
	{
		hashOffsets[i] = hashOffsets[i-1] * dimCardinals[i-1];
	}
}
